package rulescript.interps.neo;

import hscript.Expr;

@:access(rulescript.interps.NeoInterp)
class NeoInterpAccess extends RuleScriptAccess
{
	var interp:NeoInterp;

	public function new(interp:NeoInterp)
	{
		this.interp = interp;
	}

	function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	inline function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return interp.variables = newVariables;
	}

	function resetInterp():Void
	{
		interp.reset();
	}

	function variableExists(name:String):Bool
	{
		return interp.variables.exists(name);
	}

	function getVariable(name:String):Dynamic
	{
		return interp.variables[name];
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
			#if rulescript_use_hl_fixes
			Tools.__hl_callMethod(getVariable(name), args);
			#else
			Reflect.callMethod(null, getVariable(name), args);
			#end
		}
		else
			null;
	}

	function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		return #if rulescript_use_hl_fixes
			Tools.__hl_callMethod(getVariable(name), args);
		#else
			Reflect.callMethod(null, getVariable(name), args);
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

	function posInfos():haxe.PosInfos
	{
		return cast {
			fileName: scriptName ?? "hscript",
			lineNumber: interp.curLine
		}
	}
}
