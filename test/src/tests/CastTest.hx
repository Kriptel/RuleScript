package tests;

class CastTest extends Test
{
	override function test()
	{
		#if hl
		runScript("
		var a = 1.2;
		cast a;
		cast(a);
		var b = cast(a,Int);
		b;
		", 1);
		#end
	}
}
