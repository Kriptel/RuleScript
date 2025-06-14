package tests;

import example.TestEnum;
import rulescript.parsers.HxParser;
import sys.io.File;

class EnumTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = DEFAULT;

		runScript("example.TestEnum.HELLO", TestEnum.HELLO);

		runScript("a = example.TestEnum.RULESCRIPT(1.2)", () -> TestEnum.RULESCRIPT(1.2).equals(script.variables['a']));

		var module = script.getParser(HxParser).parseModule(File.getContent('scripts/enumTest/EnumTest.rhx'));
		trace(module);
	}
}
