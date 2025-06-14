package tests;

import example.ScriptedClassTest;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass.Access;
import rulescript.types.ScriptedTypeUtil;

class ScriptClassesTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = MODULE;

		// Get class
		var cl = new Access(ScriptedTypeUtil.resolveScript('scriptedClass.RuleScriptedClass.ScriptedClassStrict'));

		// Create Scripted class instance
		var instance = cl.createInstance(['hello']);

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
