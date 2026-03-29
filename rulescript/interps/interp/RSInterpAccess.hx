package rulescript.interps.interp;

import hscript.Expr;

// @:access(rulescript.interps.RuleScriptInterp)
class RSInterpAccess extends InterpAccess
{
	var interp:RuleScriptInterp;

	public function new(interp:RuleScriptInterp)
	{
		this.interp = interp;
	}

	public function getVariables():Map<String, Dynamic>
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function resetInterp():Void
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function variableExists(name:String):Bool
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function getVariable(name:String):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function removeVariable(name:String):Bool
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		throw new haxe.exceptions.NotImplementedException();
	}

	public function execute(expr:Expr):Dynamic
	{
		return interp.execute(expr);
	}

	public function posInfos():haxe.PosInfos
	{
		throw new haxe.exceptions.NotImplementedException();
	}
}
