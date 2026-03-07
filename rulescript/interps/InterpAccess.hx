package rulescript;

import hscript.Expr;

abstract class RuleScriptAccess
{
	abstract public function getVariables():Map<String, Dynamic>;

	abstract public function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>;

	abstract public function resetInterp():Void;

	abstract public function variableExists(name:String):Bool;

	abstract public function getVariable(name:String):Dynamic;

	abstract public function setVariable(name:String, value:Dynamic):Dynamic;

	abstract public function removeVariable(name:String):Bool;

	abstract public function callFunction(name:String, args:Array<Dynamic>):Dynamic;

	abstract public function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic;

	abstract public function execute(expr:Expr):Dynamic;

	abstract public function posInfos():haxe.PosInfos;
}
