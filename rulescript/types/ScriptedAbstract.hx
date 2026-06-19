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

	var opMap:Map<String, {field: String, isStatic: Bool}>;

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

	function buildOpMap() {
		if (opMap != null) return;
		opMap = new Map();

		for (field in impl.fields) {
			if (field.meta != null) {
				for (m in field.meta) {
					if (m.name == ":op" || m.name == "op") {
						if (m.params != null && m.params.length > 0) {
							var exprDef = rulescript.Tools.getExpr(m.params[0]);
							var opStr = null;
							
							switch (exprDef) {
								case EBinop(o, _, _), EUnop(o, _, _): opStr = o;
								default:
							}
							
							if (opStr != null) {
								var isStatic = field.access != null && field.access.contains(AStatic);
								opMap.set(opStr, {field: field.name, isStatic: isStatic});
							}
						}
					}
				}
			}
		}
	}

	public function hasOperator(op:String):Bool {
		if (opMap == null) buildOpMap();
		return opMap.exists(op);
	}

	public function callOperator(op:String, a:Dynamic, b:Dynamic, isRight:Bool):Dynamic {
		if (opMap == null) buildOpMap();
		
		final opData = opMap.get(op);
		if (opData == null) throw new haxe.Exception('Operator overload for "$op" not found in abstract ${impl.name}');

		final inst:ScriptedAbstractInstance = cast a;
		
		final func:Dynamic = __impl.getVariable(opData.field);
		if (func == null) throw new haxe.Exception('Function "${opData.field}" for operator "$op" is null or not found.');

		return opData.isStatic ? Reflect.callMethod(null, func, isRight ? [b, inst] : [inst, b]) : Reflect.callMethod(inst, func, [b]);
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

	public function new(impl:ScriptedAbstract, args:Array<Dynamic>)
	{
		this.impl = impl;
	}

	public function getVariables():Map<String, Dynamic> return null;

	public function variableExists(name:String):Bool
	{
		if (impl.__impl.variableExists(name)) return true;
		if (value != null) {
			try { return Reflect.hasField(value, name) || Reflect.getProperty(value, name) != null; } catch(e:Dynamic) {}
		}
		return false;
	}

	public function getVariable(name:String):Dynamic
	{
		if (impl.__impl.variableExists(name)) return impl.__impl.getVariable(name);
		
		if (value != null) {
			try { return Reflect.getProperty(value, name); } catch(e:Dynamic) {}
		}
		return null;
	}

	public function setVariable(name:String, val:Dynamic):Dynamic
	{
		if (impl.__impl.variableExists(name)) {
			var field = impl.__impl.getVariable(name);
			if (field is rulescript.types.Property) {
				cast(field, rulescript.types.Property).value = val;
				return val;
			}
		}

		if (value != null) {
			try { Reflect.setProperty(value, name, val); } catch(e:Dynamic) {}
		}
		return val;
	}
}