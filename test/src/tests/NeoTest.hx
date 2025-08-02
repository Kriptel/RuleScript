package tests;

import rulescript.RuleScript;
import rulescript.interps.NeoInterp;

class NeoTest extends Test
{
	override function test()
	{
		runScript('untyped __rulescript__interpType', 'NeoInterp');

		runScript('0', 0);
		runScript('123', 123);

		runScript('1.23', 1.23);
		runScript('12.34', 12.34);

		runScript('"Hello world"', 'Hello world');

		runScript('null', null);
		runScript('true', true);
		runScript('false', false);

		runScript('Std', RuleScript.defaultImports['']['Std']);

		runScript('var a = 123; a', 123);

		runScript('var a = 123; a = 321; a', 321);

		runScript('a = 123', () -> script.variables['a'] == 123);

		runScript('
		var a = false;
		{
			var a = true;
			trace(a);
		}
		a;', false);

		runScript('
		var a = false;
		
		if(!a) a = !a;

		if(a) 1;
		else 2;
		', 1);

		runScript('
		var a = 1 + 3 + 2.5 + 56.2;

		return a;
		');

		runScript('
		var a = new example.Test(123);
		a.test;
		', 123);
	}
}
