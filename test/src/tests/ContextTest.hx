package tests;

class ContextTest extends Test
{
	override function test()
	{
		runScript('
		import ContextTest;
		ContextTest.a;
		');
	}
}
