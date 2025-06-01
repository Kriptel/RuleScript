package rulescript.types;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.ScriptedType;
import rulescript.types.decl.AbstractDecl;

class ScriptedAbstract implements ScriptedType
{
	public var module:ScriptedModule;
	public var impl:AbstractDecl;

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
				case DAbstract(c) if (typeName == null || c.name == typeName):
					final moduleList:Array<ModuleDecl> = module.decl.copy();
					moduleList.remove(decl);

					moduleList.push(DClass({
						name: c.name,
						meta: c.meta,
						params: c.params,
						extend: null,
						implement: [],
						fields: c.fields,
						isPrivate: c.isPrivate,
						isExtern: c.isExtern
					}));

					final scriptedModule:ScriptedModule = {
						path: module.path,
						name: module.name,
						decl: moduleList
					}

					this.__impl = new ScriptedClass(scriptedModule, typeName);
				default:
			}
		}
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

	public function constructor(args:Array<Dynamic>):ScriptedAbstractInstance
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
