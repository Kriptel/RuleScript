package rulescript.types;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.ScriptedType;
import rulescript.types.decl.AbstractDecl;

@:access(rulescript.scriptedClass.ScriptedClass)
class ScriptedAbstract implements ScriptedType
{
	public var module:ScriptedModule;
	public var impl:AbstractDecl;

	var pack:String;

	public function new(impl:AbstractDecl, module:ScriptedModule)
	{
		this.module = module;

		var classImpl:ClassDecl = {
			name: impl.name,
			meta: impl.meta,
			params: impl.params,
			extend: null,
			implement: [],
			fields: impl.fields,
			isPrivate: impl.isPrivate,
			isExtern: impl.isExtern
		}

		this.__impl = new ScriptedClass(classImpl, module);
	}

	@:allow(rulescript.types.ScriptedModule)
	function init()
	{
		__impl.init();
	}

	public function compatibleWith(t:Dynamic):Bool
	{
		return t;
	}

	public function to(t:CType):Expr
	{
		return null;
	}

	public function from(o:Dynamic):Expr
	{
		return null;
	}

	@:allow(rulescript.types.ScriptedAbstractInstance)
	var __impl:ScriptedClass;

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	function get___rulescript_type():TypeID
	{
		return ABSTRACT;
	}

	#if !js
	@:deprecated
	inline public function constructor(args:Array<Dynamic>):ScriptedAbstractInstance
	{
		return createInstance(args);
	}
	#end

	public function createInstance(args:Array<Dynamic>):ScriptedAbstractInstance
	{
		return new ScriptedAbstractInstance(this, args);
	}
}

@:noBuild
class ScriptedAbstractInstance implements RuleScriptedClass
{
	public var impl:ScriptedAbstract;
	public var value:Dynamic;

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	function get___rulescript_type():TypeID
	{
		return ABSTRACT;
	}

	public function new(impl:ScriptedAbstract, value:Dynamic)
	{
		this.impl = impl;
		this.value = value;
	}

	public function getVariables():Map<String, Dynamic>
	{
		return null;
	}

	public function variableExists(name:String):Bool
	{
		return impl.__impl.variableExists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return impl.__impl.getVariable(name);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return null;
	}
}
