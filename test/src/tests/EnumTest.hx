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

		runScript('
		import example.TestEnum as NativeEnum;
		
		function a(en:NativeEnum):Int
		{
			return switch(en)
			{
				case HELLO: 1;
				case NativeEnum.WORLD: 2;
				case RULESCRIPT(_): 3;
				case RULESCRIPT(123.456): 3;
				default: -1;
			}
		}
			
		return a(NativeEnum.HELLO)+ a(NativeEnum.WORLD) + 
		a(NativeEnum.RULESCRIPT(123.456));
		', 6);

		runScript('
		import enumTest.EnumTest;
		
		function a(en:EnumTest):Int
		{
			return switch(en)
			{
				case HELLO: 1;
				case EnumTest.WORLD: 2;
				case RULESCRIPT(123.456,789): 3;
				case ABC(RULESCRIPT(123.456,"abc")): 4;
				case ABC(var v): a(v) + 5;
				default: -1;
			}
		}
			
		return a(EnumTest.HELLO) + a(EnumTest.WORLD) +
		a(EnumTest.RULESCRIPT(123.456,789))  +
		a(EnumTest.ABC(EnumTest.RULESCRIPT(123.456,"abc"))) +
		a(EnumTest.ABC(EnumTest.HELLO));
		', 16);
	}
}
