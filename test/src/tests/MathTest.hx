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
	}
}
