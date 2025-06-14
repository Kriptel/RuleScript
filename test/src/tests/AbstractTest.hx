package tests;

import example.HelloWorldAbstract;
import example.TestAbstract;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass.Access;
import rulescript.types.ScriptedTypeUtil;
import sys.io.File;

class AbstractTest extends Test
{
	override function test()
	{
		runScript('
            import hello.TestAbstract;

            TestAbstract.helloworld;
        ', TestAbstract.helloworld);

		runScript('
            example.HelloWorldAbstract.rulescriptPrint();
        ', HelloWorldAbstract.rulescriptPrint());

		var cl = new Access(ScriptedTypeUtil.resolveScript('abstracts.Main'));
		cl.main();

		script.getParser(HxParser).mode = DEFAULT;

		var module = script.getParser(HxParser).parseModule(File.getContent('scripts/abstracts/AbstractTest.rhx'));
		trace(module);
	}
}
