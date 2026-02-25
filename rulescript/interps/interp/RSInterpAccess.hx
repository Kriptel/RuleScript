package rulescript.interps.interp;

import hscript.Expr;
import rulescript.scriptedClass.ScriptedConstructor;

@:access(rulescript.interps.RuleScriptInterp)
class RSInterpAccess extends RuleScriptAccess
{
	var interp:RuleScriptInterp;

	public function new(interp:RuleScriptInterp)
	{
		this.interp = interp;
	}

	function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return interp.variables = newVariables;
	}

	function resetInterp():Void
	{
		interp.resetVariables();
	}

	function variableExists(name:String):Bool
	{
		return interp.variables.exists(name);
	}

	function getVariable(name:String):Dynamic
	{
		return interp.variables[name];
	}

	function posInfos():haxe.PosInfos
	{
		return interp.posInfos();
	}

	function setVariable(name:String, value:Dynamic):Dynamic
	{
		return interp.variables[name] = value;
	}

	function removeVariable(name:String):Bool
	{
		return interp.variables.remove(name);
	}

	function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		return if (variableExists(name))
		{
			#if hl
			Tools.__hl_callMethod(interp.variables[name], args);
			#else
			Reflect.callMethod(null, interp.variables[name], args);
			#end
		}
		else
			null;
	}

	function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		return #if hl
			Tools.__hl_callMethod(interp.variables[name], args);
		#else
			Reflect.callMethod(null, interp.variables[name], args);
		#end
	}

	function execute(expr:Expr):Dynamic
	{
		return interp.execute(expr);
	}

	function get_scriptName():String
	{
		return interp.scriptName;
	}

	function set_scriptName(v:String):String
	{
		return interp.scriptName = v;
	}

	function get_scriptPackage():String
	{
		return interp.scriptPackage;
	}

	function set_scriptPackage(v:String):String
	{
		return interp.scriptPackage = v;
	}

	function get_superInstance():Dynamic
	{
		return interp.superInstance;
	}

	function set_superInstance(v:Dynamic):Dynamic
	{
		return interp.superInstance = v;
	}

	function get_hasErrorHandler():Bool
	{
		return interp.hasErrorHandler;
	}

	function set_hasErrorHandler(v:Bool):Bool
	{
		return interp.hasErrorHandler = v;
	}

	function get_errorHandler():haxe.Exception->Void
	{
		return interp.errorHandler;
	}

	function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
	{
		return interp.errorHandler = v;
	}

	function get_context():Context
	{
		return interp.context;
	}

	function set_context(v:Context):Context
	{
		return interp.context = v;
	}

	function get_isSuperCall():Bool
	{
		return interp.isSuperCall;
	}

	function set_isSuperCall(v:Bool):Bool
	{
		return interp.isSuperCall = v;
	}

	override function get_hasConstructor():Bool
	{
		return interp.__constructor != null;
	}

	override function createConstructor(args:Array<Dynamic>):ScriptedConstructor
	{
		var c = interp.__constructor;
		c.initCall(args);
		return c;
	}

	override function __resolve(path:String):Dynamic
	{
		return interp.resolve(path);
	}

	override function __resolveType(path:String):Dynamic
	{
		return interp.resolveType(path);
	}
}
