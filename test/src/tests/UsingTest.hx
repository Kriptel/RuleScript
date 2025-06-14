package tests;

using Reflect;

class UsingTest extends Test
{
	override function test()
	{
		runScript('using Reflect;
		
		return "11".getProperty("length");
		', "11".getProperty("length"));
	}
}
