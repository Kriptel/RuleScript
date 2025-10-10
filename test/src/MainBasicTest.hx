package;

import Main.*;
import rulescript.RuleScript.IInterp;
import rulescript.interps.*;
import tests.*;

function test()
{
	final tests:Array<Test> = [
		new InterpTest(),
		new MathTest(),
		new ImportTest(),
		new UsingTest(),
		new StringInterpolationTest(),
		new RegexTest(),
		new AbstractTest(),
		new TypedefTest(),
		new TypePathTest(),
		new ModuleTest(),
		new ScriptClassesTest(),
		new FileScriptTest(),
		new EnumTest(),
		new CastTest(),
		new ContextTest()
	];

	for (test in tests)
	{
		test.script = script;
	}

	final interps:Array<{name:String, interp:IInterp}> = [
		{name: 'RuleScriptInterp', interp: new RuleScriptInterp()},
		{name: "BytecodeInterp", interp: new BytecodeInterp()}
		// ,{name: "NeoInterp", interp: new NeoInterp()}
	];

	for (interp in interps)
	{
		print('\nCurrent Interp: ${interp.name}');

		Test.interpNum++;
		Test.callNum = 0;
		script.interp = interp.interp;

		for (test in tests)
		{
			test.test();
		}
	}

	print('\n\tTests:[${Test.interpNum}/${Test.callNum}],\n\tErrors: ${Test.errorsNum}');
}
