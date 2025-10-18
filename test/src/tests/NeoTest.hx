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

		runScript('"A" != "B"', "A" != "B");

		runScript('"A" == "B"', "A" == "B");

		runScript('0 == 1', 0 == 1);
		runScript('0 != 1', 0 != 1);
		runScript('0 > 1', 0 > 1);
		runScript('0 >= 1', 0 >= 1);
		runScript('0 <= 1', 0 <= 1);
		runScript('0 < 1', 0 < 1);

		runScript('
		var a = 0;
		
		for(i in [1,2,3,4,5,6,7,8,9,10])
			a += i;

		a;
		', {
				var a = 0;

				for (i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
					a += i;

				a;
			});

		runScript("
		var a = '';
		
		for(id => i in 'RuleScript'.split(''))
			a += '$id $i, ';

		a;
		", {
				var a = '';

				for (id => i in 'RuleScript'.split(''))
					a += '$id $i, ';

				a;
			});

		runScript('
		var a = 1;
		
		while(a < 100)
			a *= 2;

		a;
		', {
				var a = 1;

				while (a < 100)
					a *= 2;

				a;
			});

		runScript('
		var a = 1;
		
		do {
			a *= 2;
		}
		while(a < 100);

		a;
		', {
				var a = 1;

				do
				{
					a *= 2;
				}
				while (a < 100);

				a;
			});

		runScript('
		var a:Dynamic = try
		{
			var b:Dynamic = {};
			b.c();
		}
		catch (e:Dynamic)
		{
			"2";
		}

		a;
		', {
				var a:Dynamic = try
				{
					var b:Dynamic = {};
					b.c();
				}
				catch (e:Dynamic)
				{
					"2";
				}

				a;
			});

		runScript('
		import Reflect;
		import Reflect as AliasReflect;
		import Reflect.getProperty;
		import Reflect.getProperty as gp;

		return Reflect == AliasReflect && Reflect.getProperty == getProperty && getProperty == gp;
		', true);
	}
}
