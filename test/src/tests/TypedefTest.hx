package tests;

import rulescript.parsers.HxParser;
import rulescript.types.Typedefs;

class TypedefTest extends Test
{
	override function test()
	{
		Typedefs.register('hello.world.HxParser', HxParser);
		runScript('hello.world.HxParser', HxParser);
	}
}
