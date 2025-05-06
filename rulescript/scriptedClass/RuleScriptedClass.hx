package rulescript.scriptedClass;

import hscript.Expr.ClassDecl;
import hscript.Expr.ModuleDecl;
import rulescript.interps.RuleScriptInterp;
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

	inline public function createInstance(?args:Array<Dynamic>):Access
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).createInstance(args) : throw 'createInstance is only allowed for ScriptedClass';
	}

	inline function get_constructor():Array<Dynamic>->Dynamic
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).constructor : throw 'Constructor is only allowed for ScriptedClass';
	}

	inline function set_constructor(value:Array<Dynamic>->Dynamic):Array<Dynamic>->Dynamic
	{
		return abstract is ScriptedClass ? cast(this, ScriptedClass).constructor = value : throw 'Constructor is only allowed for ScriptedClass';
	}
}

typedef ScriptedModule =
{
	var path:String;
	var name:String;
	var decl:Array<ModuleDecl>;
}

@:noBuild class ScriptedClass implements RuleScriptedClass
{
	public var module:ScriptedModule;
	public var impl:ClassDecl;
	public var superClass:Null<Dynamic>;
	public var nativeClass:Null<Dynamic>;
	public var constructor:(args:Array<Dynamic>) -> Dynamic;

	public var interp:RuleScriptInterp;

	var pack:String;

	public function new(module:ScriptedModule, ?typeName:String)
	{
		this.module = module;

		for (decl in module.decl)
		{
			switch (decl)
			{
				case DPackage(path):
					pack = path.join('.');
				case DClass(c) if (typeName == null || c.name == typeName):
					this.impl = c;
				case _:
			}
		}

		interp = new RuleScriptInterp();
		interp.execute(Tools.moduleDeclsToExpr(module.decl, {
			fieldFilter: f -> f.access.contains(AStatic)
		}));

		if (impl.extend != null)
		{
			var type = Tools.typeToString(impl.extend);

			@:privateAccess {
				// Check module
				superClass ??= interp.resolveType('${((pack.length > 0) ? pack + '.' : '')}${module.name}.$type');
				// Check type
				superClass ??= interp.resolveType(type);
				// Check imported types
				superClass ??= interp.resolve(type);
			}

			if (superClass == null)
				throw 'Type not found : $type';
		}

		if (superClass != null)
		{
			if (superClass is ScriptedClass)
			{
				nativeClass = superClass.nativeClass;
			}
			else
			{
				nativeClass = superClass;
			}
		}

		constructor = if (nativeClass == null && (superClass == null || superClass is ScriptedClass))
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
			throw '$superClass cannot be constructed';
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	private function get___rulescript_type():TypeID
	{
		return CLASS;
	}

	public function createInstance(?args:Array<Dynamic>):Dynamic
	{
		return constructor(args ?? []);
	}

	public function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	public function variableExists(name:String):Bool
	{
		return interp.variables.exists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return interp.variables[name];
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return interp.variables[name] = value;
	}

	public function toString():String
	{
		return if (variableExists('toString'))
			getVariable('toString')();
		else
		{
			(interp.scriptPackage != '' ? interp.scriptPackage + '.' : '') + (module.name != impl.name ? module.name + '.' + impl.name : impl.name);
		}
	}
}

@:noBuild class ScriptedInstance implements RuleScriptedClass
{
	var cl:ScriptedClass;

	public var interp:RuleScriptInterp;

	var _superInstance:ScriptedInstance;

	public var variables:Map<String, Dynamic> = [];

	@:access(rulescript.scriptedClass.ScriptedClass)
	public function new(cl:ScriptedClass, args:Array<Dynamic>)
	{
		this.cl = cl;

		interp = new RuleScriptInterp();

		var list = [];

		var currentClass:ScriptedClass = cl;

		while (currentClass != null)
		{
			list.insert(0, currentClass);
			currentClass = currentClass.superClass;
		}

		for (cl in list)
		{
			interp.execute(Tools.toExpr(EBlock([
				Tools.moduleDeclsToExpr(cl.module.decl, {
					isScriptedClass: true,
					fieldFilter: f -> !f.access.contains(AStatic)
				})
			])));

			for (field in cl.impl.fields)
			{
				if (!field.access.contains(AStatic))
					setVariable(field.name, interp.variables[field.name]);
			}
		}

		interp.superInstance = this;

		if (args != null)
			if (variableExists('new'))
				Reflect.callMethod(this, getVariable('new'), args);
			else
				throw '${cl.pack + '.' + cl.impl.name} does not have a constructor';
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	private function get___rulescript_type():TypeID
	{
		return CLASS;
	}

	public function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	public function variableExists(name:String):Bool
	{
		return variables.exists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return variables[name];
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return variables[name] = value;
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
}
