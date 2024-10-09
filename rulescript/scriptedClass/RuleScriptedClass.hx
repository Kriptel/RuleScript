package rulescript.scriptedClass;

@:autoBuild(rulescript.macro.RuleScriptedClass.build())
interface RuleScriptedClass
{
	function variableExists(name:String):Bool;
	function getVariable(name:String):Dynamic;
	function setVariable(name:String, value:Dynamic):Dynamic;
}
