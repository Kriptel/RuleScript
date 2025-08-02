package tests;

class MathTest extends Test
{
	override function test()
	{
		runScript('1 + 7', 1 + 7);
		runScript('1 - 2', 1 - 2);
		runScript('15 * 2', 15 * 2);
		runScript('10 / 2', 10 / 2);

		runScript('5 + 5 * 2', 5 + 5 * 2);
		runScript('1.1 + 2.53 + 122', 1.1 + 2.53 + 122);
		runScript('(15 * 2) + (12 / 2)', (15 * 2) + (12 / 2));
		runScript('2 / (3 * 5)', 2 / (3 * 5));

		runScript('1.153', 1.153);

		runScript('123 % 2', 123 % 2);

		runScript('123 << 1', 123 << 1);
		runScript('123 >> 1', 123 >> 1);
		runScript('123 >>> 1', 123 >>> 1);
		runScript('123 & 1', 123 & 1);
		runScript('123 | 1', 123 | 1);
		runScript('123 ^ 1', 123 ^ 1);
		runScript('~123', ~123);
		runScript('-123', -123);

		runScript('var i = 0; ++i;', {var i = 0; ++i;});
		runScript('var i = 0; i++;', {var i = 0; i++;});

		runScript('var i = 0; --i;', {var i = 0; --i;});
		runScript('var i = 0; i--;', {var i = 0; i++;});

		runScript('var i = [0]; ++i[0];', {var i = [0]; ++i[0];});
		runScript('var i = [0]; i[0]++;', {var i = [0]; i[0]++;});

		runScript('var i = [0]; --i[0];', {var i = [0]; --i[0];});
		runScript('var i = [0]; i[0]--;', {var i = [0]; i[0]++;});

		runScript('var a = {b:0}; ++a.b;', {var a = {b: 0}; ++a.b;});
		runScript('var a = {b:0}; a.b++;', {var a = {b: 0}; a.b++;});

		runScript('var a = {b:0}; --a.b;', {var a = {b: 0}; --a.b;});
		runScript('var a = {b:0}; a.b--;', {var a = {b: 0}; a.b--;});
	}
}
