package rulescript.scriptedClass;

import hscript.Expr.ClassDecl;
import rulescript.RuleScript.IInterp;
import rulescript.Tools.TypePath;
import rulescript.types.ScriptedModule;
import rulescript.types.ScriptedType;

@:autoBuild(rulescript.macro.RuleScriptedClassMacro.build())
interface RuleScriptedClass extends ScriptedType
{
	function getVariables():Map<String, Dynamic>;
	function variableExists(name:String):Bool;
	function getVariable(name:String):Dynamic;
	function setVariable(name:String, value:Dynamic):Dynamic;
}

@:forward
abstract Access(RuleScriptedClass)
{
	/**
	 * Returns the contents of the wrapper with the given type
	 * 
	 * @param t The given type.
	 * @return T
	 */
	inline public function self<T:RuleScriptedClass>(?t:T):T
	{
		return cast this;
	}

	/**
	 * The constructor of the scripted class, this is also referred to as `new`. 
	 */
	public var constructor(get, set):(args:Array<Dynamic>) -> Dynamic;

	public function new(cl:RuleScriptedClass)
	{
		this = cl;
	}

	@:op(a.b)
	inline function get(variable:String):Dynamic
	{
		return this.getVariable(variable);
	}

	@:op(a.b)
	inline function set(variable:String, value:Dynamic):Dynamic
	{
		return this.setVariable(variable, value);
	}

	/**
	 * This method allows you to create an instance of a scripted class.
	 * If unsuccessful, it'll throw an error. 
	 * 
	 * @param args The scripted class instance arguments. (This is an optional parameter)
	 * @return Returns an instance of `Access`.
	 */
	inline public function createInstance(?args:Array<Dynamic>):Access
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).createInstance(args) : throw 'createInstance is only allowed for ScriptedClass';
	}

	inline function get_constructor():Array<Dynamic>->Dynamic
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).initialize : throw 'Constructor is only allowed for ScriptedClass';
	}

	inline function set_constructor(value:Array<Dynamic>->Dynamic):Array<Dynamic>->Dynamic
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).initialize = value : throw 'Constructor is only allowed for ScriptedClass';
	}
}

@:access(rulescript.RuleScriptAccess)
@:noBuild class ScriptedClass implements RuleScriptedClass
{
	public var className:String;
	public var module:ScriptedModule;
	public var impl:ClassDecl;

	public var superClass:Null<Dynamic>;
	public var nativeClass:Null<Dynamic>;

	var interp:IInterp;

	public var initialize:(args:Array<Dynamic>) -> Dynamic;

	#if !js
	@:deprecated('ScriptedClass.constructor was moved to ScriptedClass.createInstance')
	public var constructor(get, set):(args:Array<Dynamic>) -> Dynamic;

	inline function get_constructor():(args:Array<Dynamic>) -> Dynamic
	{
		return initialize;
	}

	inline function set_constructor(f:(args:Array<Dynamic>) -> Dynamic):(args:Array<Dynamic>) -> Dynamic
	{
		return initialize = f;
	}
	#end

	public function new(impl:ClassDecl, module:ScriptedModule)
	{
		this.impl = impl;
		this.module = module;

		className = impl.name;

		interp = RuleScript.createInterp();
		@:privateAccess interp.access.context = module.context;
		interp.access.setVariable(className, this);
	}

	var initialized:Bool = false;

	@:allow(rulescript.types.ScriptedModule)
	function init()
	{
		if (initialized)
			return;
		else
			initialized = true;

		for (name => type in module.types)
		{
			interp.access.setVariable(name, type);
		}

		interp.access.execute(Tools.moduleDeclsToExpr(module.sharedDecls, {
			fieldFilter: f -> f.access.contains(AStatic),
			classImpl: impl
		}));

		if (impl.extend != null)
		{
			var type = Tools.typeToString(impl.extend);

			@:privateAccess {
				// Check module
				superClass ??= module.types[type];
				// Check type
				superClass ??= interp.access.__resolveType(type);
				// Check imported types
				superClass ??= interp.access.__resolve(type);
			}

			if (superClass == null)
				throw 'Type not found : $type';
		}

		if (superClass != null)
		{
			if (superClass is ScriptedClass)
			{
				superClass.init();

				nativeClass = superClass.nativeClass;
			}
			else
			{
				nativeClass = superClass;
			}
		}

		initialize = if (nativeClass == null && (superClass == null || superClass is ScriptedClass))
			ScriptedInstance.new.bind(this, _)
		else if (nativeClass != null)
		{
			var type = toString();

			var strict = Reflect.getProperty(nativeClass, '__rulescript_strict');

			if (strict)
				args ->
				{
					var strictArgs:Array<Dynamic> = [type];

					for (arg in args)
						strictArgs.push(arg);

					#if hl
					Tools.__hl_createInstance(nativeClass, strictArgs);
					#else
					Type.createInstance(nativeClass, strictArgs);
					#end
				}
			else
				args ->
					#if hl
					Tools.__hl_createInstance(nativeClass, [type, args]);
					#else
					Type.createInstance(nativeClass, [type, args]);
					#end
		}
		else
			(_) -> throw toString() + ' cannot be constructed';

		interp.access.scriptName = toString();
	}

	public function getVariables():Map<String, Dynamic>
	{
		return interp.access.getVariables();
	}

	public function variableExists(name:String):Bool
	{
		return interp.access.variableExists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return interp.access.getVariable(name);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return interp.access.setVariable(name, value);
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	private function get___rulescript_type():TypeID
	{
		return CLASS;
	}

	public function createInstance(args:Array<Dynamic>)
	{
		return initialize(args ?? []);
	}

	@:access(rulescript.RuleScriptAccess)
	public function toString():String
	{
		return if (variableExists('toString'))
			getVariable('toString')();
		else
		{
			TypePath.createString(interp.access.scriptPackage.split('.'), module.name, impl.name);
		}
	}
}

@:access(rulescript.RuleScriptAccess)
@:access(rulescript.types.ScriptedClass)
@:noBuild class ScriptedInstance implements RuleScriptedClass
{
	var cl:ScriptedClass;

	public var interp:IInterp;

	public var variables(get, set):Map<String, Dynamic>;

	public function new(cl:ScriptedClass, args:Array<Dynamic>)
	{
		this.cl = cl;

		interp = RuleScript.createInterp();
		interp.access.scriptName = cl.toString();

		final list:Array<Dynamic> = [];

		var currentClass:Dynamic = cl;

		while (currentClass != null)
		{
			if (currentClass is ScriptedClass)
			{
				final sc:ScriptedClass = cast currentClass;
				list.insert(0, sc);
				setVariable(sc.className, sc);

				currentClass = sc.superClass;
			}
			else
			{
				setVariable(Type.getClassName(currentClass), currentClass);

				break;
			}
		}

		for (cl in list)
		{
			interp.access.execute(Tools.toExpr(EBlock([
				Tools.moduleDeclsToExpr(cl.module.sharedDecls, {
					isScriptedClass: true,
					fieldFilter: f -> !f.access.contains(AStatic),
					classImpl: cl.impl
				})
			])));
		}

		interp.access.superInstance = this;

		if (args != null)
			if (variableExists('new'))
				Reflect.callMethod(this, getVariable('new'), args);
			else
				throw '${cl.toString()} does not have a constructor';
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	private function get___rulescript_type():TypeID
	{
		return CLASS;
	}

	public function getVariables():Map<String, Dynamic>
	{
		return interp.access.getVariables();
	}

	public function variableExists(name:String):Bool
	{
		return interp.access.variableExists(name) || cl.variableExists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return interp.access.getVariable(name) ?? cl.getVariable(name);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return cl.variableExists(name) ? cl.setVariable(name, value) : interp.access.setVariable(name, value);
	}

	public function toString():String
	{
		return if (variableExists('toString'))
			getVariable('toString')();
		else
		{
			cl.toString();
		}
	}

	function get_variables():Map<String, Dynamic>
	{
		return interp.access.getVariables();
	}

	function set_variables(v:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return interp.access.setVariables(v);
	}
}
