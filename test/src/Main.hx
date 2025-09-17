package;

import example.HelloWorldAbstract;
import example.ScriptedClassTest;
import example.TestAbstract;
import hscript.Expr.ClassDecl;
import hscript.Expr.ModuleDecl;
import rulescript.Context;
import rulescript.RuleScript;
import rulescript.interps.BytecodeInterp;
import rulescript.interps.NeoInterp;
import rulescript.interps.RuleScriptInterp;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.scriptedClass.RuleScriptedClassUtil;
import rulescript.types.ScriptedTypeUtil;
import rulescript.types.Typedefs;
import tests.*;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Main
{
	static var script:RuleScript;

	static var callNum:Int = 0;
	static var errorsNum:Int = 0;

	static function main():Void
	{
		example.Test.LocalHelloClass.init();
		HelloWorldAbstract.RULESCRIPT;

		print('========\nCurrent target: ' + #if cpp 'cpp' #elseif hl 'hl' #elseif eval 'eval' #else 'other' #end
			+ '\n========');

		// RuleScript.createInterp = () ->
		// {
		// 	var interp = new BytecodeInterp();
		// 	interp.staticOptimization = false;
		// 	interp;
		// };

		ScriptedTypeUtil.resolveModule = resolveModule;

		script = new RuleScript(new HxParser(), new Context());
		script.scriptName = 'rulescript.test';
		script.getParser(HxParser).allowAll();

		#if !neoInterp_test
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
		#else
		script.interp = new NeoInterp();

		final neoTest = new NeoTest();
		neoTest.script = script;

		neoTest.test();
		#end

		print('\n\tTests:[${Test.interpNum}/${Test.callNum}],\n\tErrors: ${Test.errorsNum}');
	}

	public static function resolveModule(name:String):Array<ModuleDecl>
	{
		#if sys
		var path:Array<String> = name.split('.');

		var pack:Array<String> = [];

		while (path[0].charAt(0) == path[0].charAt(0).toLowerCase())
			pack.push(path.shift());

		var moduleName:String = null;

		if (path.length > 1)
			moduleName = path.shift();

		// Replace type path dots to slash.
		var filePath = 'scripts/${(pack.length >= 1 ? pack.join('.') + '.' + (moduleName ?? path[0]) : path[0]).replace('.', '/')}.rhx';

		// Check file.
		if (!FileSystem.exists(filePath))
			return null;

		// Parse code.
		var parser = new HxParser();
		parser.allowAll();
		parser.mode = MODULE;

		return parser.parseModule(File.getContent(filePath));
		#else
		return [];
		#end
	}

	static function onError(e:haxe.Exception):Dynamic
	{
		errorsNum++;
		trace('[ERROR] : ${e.details()}');
		return e.details();
	}

	public static function print(v:Dynamic)
	{
		#if sys
		Sys.println(v);
		#else
		trace(v);
		#end
	}
}
