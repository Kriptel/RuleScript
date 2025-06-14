package tests;

import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass.Access;
import rulescript.types.ScriptedTypeUtil;

class FileScriptTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = DEFAULT;
		runFileScript('PropertyTest.rhx', 'Hello World');

		script.getParser(HxParser).mode = MODULE;
		runFileScript('test.rhx');

		script.access.callFunctionUnsafe('main', []);

		runFileScript('importTest/ScriptImportTest.rhx');

		script.variables.get('main')();

		// Scripted class
		var ScriptedClassC:Access = new Access(ScriptedTypeUtil.resolveScript('scriptedClass.ScriptedClass.ScriptedClassC'));

		// Scripted class instance
		var instance = ScriptedClassC.createInstance();
		instance.hello();
	}
}
