package tests;

class StringInterpolationTest extends Test
{
	override function test()
	{
		final a:Int = 123;
		final b:{c:Int} = {c: 123};

		script.access.setVariable('a', a);
		script.access.setVariable('b', b);

		runScript("''", '');
		runScript("'$'", '$');
		runScript("'$$'", '$$');
		runScript("'$a'", '$a');
		runScript("'${a}'", '${a}');
		runScript("'123 $a'", '123 $a');
		runScript("'$a 123'", '$a 123');
		runScript("'$$a 123'", '$$a 123');
		runScript("'$$$a 123'", '$$$a 123');
		runScript("'$2'", '$2');
		runScript("'${a}${b}'", '${a}${b}');
		runScript("'123 ${a}${b}'", '123 ${a}${b}');
		runScript("'123 ${a} ${b}'", '123 ${a} ${b}');
		runScript("'${a} ${b} 123'", '${a} ${b} 123');

		script.access.removeVariable('a');
		script.access.removeVariable('b');
	}
}
