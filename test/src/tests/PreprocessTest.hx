package tests;

import rulescript.parsers.HxParser;

class PreprocessTest extends Test
{
	override function test()
	{
		script.context.defines.set('test', '1');
		script.parser.as(HxParser).parser.preprocesorValues.set('test2', '2');

		assert('
        var a = 0;

        #if test
        a += 1; 
        #end

        #if (test2 > 1)
        a += 1;
        #elseif test
        a -= 1;
        #end

        a;
        ', 2);
	}
}
