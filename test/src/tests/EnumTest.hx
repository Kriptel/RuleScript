package tests;

import example.TestEnum;
import rulescript.parsers.HxParser;

class EnumTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = DEFAULT;

		runScript("example.TestEnum.HELLO", TestEnum.HELLO);

		runScript("a = example.TestEnum.RULESCRIPT(1.2)", () -> TestEnum.RULESCRIPT(1.2).equals(script.variables['a']));

		#if sys
		var module = script.getParser(HxParser).parseModule(sys.io.File.getContent('scripts/enumTest/EnumTest.rhx'));
		trace(module);
		#end
	}
}
