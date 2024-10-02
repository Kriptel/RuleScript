package test;

import rulescript.scriptedClass.RuleScriptedClass;

class Hello<T>
{
	var v:T;

	public function new(value:T)
	{
		v = value;
	}
}

class SrcClassTest<T:Hello<K>, K>
{
	var a:Int = 1;
	var b:T;
	var c:Array<T>;
	var d:() -> T;

	public function new(arg1:String) {}

	final finalVar:Int = 1;

	final public function finalFunc():Int
	{
		return finalVar;
	}

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

	public function argFunction2(a1:Bool = true, a2:String, a3:String)
	{
		return '$a1, $a2, $a3';
	}

	public function string(arg:T)
	{
		return Std.string(arg);
	}

	public function t(arg:T):T
	{
		return arg;
	}

	public function stringArray(arg:Array<T>)
		return Std.string(arg);

	public static function staticField() {}
}

class SrcClassTest2 extends SrcClassTest<Hello<Dynamic>, Dynamic> {}
class ScriptedClassTest implements RuleScriptedClass extends SrcClassTest2 {}
