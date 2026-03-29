package tests;

class MathTest extends Test
{
	override function test()
	{
		assert('1 + 7', 1 + 7);
		assert('1 - 2', 1 - 2);
		assert('15 * 2', 15 * 2);
		assert('10 / 2', 10 / 2);

		assert('1e-3', 1e-3);
		assert('1e+3', 1e+3);

		assert('5 + 5 * 2', 5 + 5 * 2);
		assert('1.1 + 2.53 + 122', 1.1 + 2.53 + 122);
		assert('(15 * 2) + (12 / 2)', (15 * 2) + (12 / 2));
		assert('2 / (3 * 5)', 2 / (3 * 5));

		assert('1.153', 1.153);

		assert('123 % 2', 123 % 2);

		assert('123 << 1', 123 << 1);
		assert('123 >> 1', 123 >> 1);
		assert('123 >>> 1', 123 >>> 1);
		assert('123 & 1', 123 & 1);
		assert('123 | 1', 123 | 1);
		assert('123 ^ 1', 123 ^ 1);
		assert('~123', ~123);
		assert('-123', -123);

		assert('var i = 0; ++i;', {var i = 0; ++i;});
		assert('var i = 0; i++;', {var i = 0; i++;});

		assert('var i = 0; --i;', {var i = 0; --i;});
		assert('var i = 0; i--;', {var i = 0; i++;});

		assert('var i = [0]; ++i[0];', {var i = [0]; ++i[0];});
		assert('var i = [0]; i[0]++;', {var i = [0]; i[0]++;});

		assert('var i = [0]; --i[0];', {var i = [0]; --i[0];});
		assert('var i = [0]; i[0]--;', {var i = [0]; i[0]++;});

		assert('var a = {b:0}; ++a.b;', {var a = {b: 0}; ++a.b;});
		assert('var a = {b:0}; a.b++;', {var a = {b: 0}; a.b++;});

		assert('var a = {b:0}; --a.b;', {var a = {b: 0}; --a.b;});
		assert('var a = {b:0}; a.b--;', {var a = {b: 0}; a.b--;});
	}
}
