package test;

import rulescript.scriptedClass.RuleScriptedClass;

class SrcClassTest
{
	public function new() {}

	public function info()
	{
		return 'ScrClassTest';
	}

	public function intInfo():Int
	{
		return 0;
	}

	public function argFunction(a1:Bool, a2:String, a3:String)
	{
		return '$a1, $a2, $a3';
	}

	public static function staticField() {}
}

class ScriptedClassTest implements RuleScriptedClass extends SrcClassTest {}
