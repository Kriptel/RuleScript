package tests;

class RegexTest extends Test
{
	override function test()
	{
		runScript('~/haxe/i');

		runScript('~/haxe/');

		runScript('~/[A-Z0-9._%-]+@[A-Z0-9.-]+\\.[A-Z][A-Z][A-Z]*/i;');
	}
}
