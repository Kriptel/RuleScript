package tests;

import example.ScriptedClassTest;
import rulescript.RuleScript;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass.Access;

class ScriptClassesTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = MODULE;

		// Get class
		var cl:Access = RuleScript.resolveScriptedClass('scriptedClass.RuleScriptedClass.ScriptedClassStrict', context);

		// Create Scripted class instance
		var instance = cl.createInstance(['hello']);
		// alternative method:
		var instance = RuleScript.createScriptedInstance('scriptedClass.RuleScriptedClass.ScriptedClassStrict', ['hello'], context);

		// Custom constructor can't have extra args, if it strict
		new ScriptedClassTestStrict('scriptedClass.RuleScriptedClass.ScriptedClassStrict', 'Script');

		var srcClass = new SrcClassTest<Hello<Int>, Int>('Src'),
			scriptClass = new ScriptedClassTest('scriptedClass.RuleScriptedClass.ScriptedClass', [4, 'Script']);

		// Compare
		trace(srcClass.info());
		trace(scriptClass.info());

		trace(srcClass.argFunction(true, 'hello', 'world'));
		trace(scriptClass.argFunction(true, 'hello', 'world'));

		trace(srcClass.string(new Hello<Int>(12)));
		trace(scriptClass.string(new Hello<String>('hello')));

		trace(srcClass.stringArray([new Hello<Int>(12)]));
		trace(scriptClass.stringArray([new Hello<String>('hello')]));

		trace(scriptClass);

		if (scriptClass.variableExists('scriptFunction'))
			trace(scriptClass.getVariable('scriptFunction')());
	}
}
