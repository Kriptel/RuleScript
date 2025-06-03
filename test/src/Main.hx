package;

import hscript.Expr.ClassDecl;
import hscript.Expr.ModuleDecl;
import hscript.Printer;
import rulescript.RuleScript;
import rulescript.interps.BytecodeInterp;
import rulescript.interps.RuleScriptInterp;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.scriptedClass.RuleScriptedClassUtil;
import rulescript.types.ScriptedTypeUtil;
import rulescript.types.Typedefs;
import sys.FileSystem;
import sys.io.File;
import test.HelloWorldAbstract;
import test.ScriptedClassTest;
import test.TestAbstract;

using StringTools;

class Main
{
	static var script:RuleScript;

	static var callNum:Int = 0;
	static var errorsNum:Int = 0;

	static function main():Void
	{
		test.Test.LocalHelloClass.init();
		HelloWorldAbstract.RULESCRIPT;

		trace('Testing Commands:');

		RuleScript.createInterp = () ->
		{
			var interp = new BytecodeInterp();
			interp.staticOptimization = false;
			interp;
		};

		script = new RuleScript(new HxParser());

		script.scriptName = 'rulescript.test';

		script.getParser(HxParser).allowAll();

		script.errorHandler = onError;

		ScriptedTypeUtil.resolveModule = resolveModule;

		runScript('untyped __rulescript__interpType');

		try
		{
			mathTest();
			packageTest();
			importAndUsingTest();
			stringInterpolationTest();
			abstractTest();
			typedefTest();
			typePathTest();
			moduleTest();
			scriptClassesTest();
			fileScriptTest();
			enumTest();
			castTest();
		}
		catch (e)
			trace(e?.details());

		Sys.println('\n\tTests:$callNum,\n\tErrors: $errorsNum');
	}

	static function mathTest()
	{
		// Math
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

	static function packageTest()
	{
		runScript('package', () -> script.scriptPackage == '');

		runScript('package scripts.hello.world', () -> script.scriptPackage == 'scripts.hello.world');
	}

	static function importAndUsingTest()
	{
		// Test object.
		script.variables.set('a', {hello: 'world'});

		// Import.
		runScript('
            Reflect.getProperty(a,"hello");
        ', 'world');

		// Import with alias.
		runScript('
            import Reflect as AliasReflect;

            AliasReflect.getProperty(a,"hello");
        ', 'world');

		// Class field import.
		runScript('
            import Reflect.getProperty;

            getProperty(a,"hello");
        ', 'world');

		// Class field import with alias.
		runScript('
            import Reflect.getProperty as get;

            get(a,"hello");
        ', 'world');

		// Using;
		runScript('
            using Reflect;
            
            a.getProperty("hello");
        ', 'world');

		script.variables.remove('a');
	}

	static function stringInterpolationTest()
	{
		runScript("
		var a = 'Hello';
		return 'RuleScript: $a World';
		", 'RuleScript: Hello World');

		runScript("
		var a = 'World';
		'RuleScript: Hello $a';
		", 'RuleScript: Hello World');

		script.variables.set('a', {hello: 'World'});

		runScript("
            var a = {
                a:'RuleScript',
                b: () -> 'Hello',
                c:'World'
            };
        
            return a.a + ' ' + a.b() + ' ' + a.c;
        ", 'RuleScript Hello World');

		runScript("
            var a = {
                a:'RuleScript',
                b: () -> 'Hello',
                c:'World'
            };
        
            return '${a.a}: ${a.b() + \" \" + a.c}';
        ");

		script.variables.remove('a');
	}

	static function abstractTest()
	{
		runScript('
            import hello.TestAbstract;

            TestAbstract.helloworld;
        ', TestAbstract.helloworld);

		runScript('
            test.HelloWorldAbstract.rulescriptPrint();
        ', HelloWorldAbstract.rulescriptPrint());

		var cl = new Access(ScriptedTypeUtil.resolveScript('abstracts.Main'));
		cl.main();

		script.getParser(HxParser).mode = DEFAULT;

		var module = script.getParser(HxParser).parseModule(File.getContent('scripts/abstracts/AbstractTest.rhx'));
		trace(module);
	}

	static function typedefTest()
	{
		Typedefs.register('hello.world.HxParser', HxParser);
		runScript('hello.world.HxParser', HxParser);
	}

	static function typePathTest()
	{
		runScript('
            sys.FileSystem;
        ', sys.FileSystem);

		var a = {FileSystem: "hello world"};

		script.variables.set('sys', a);

		runScript('
            sys.FileSystem;
        ', "hello world");

		script.variables.remove('sys');
	}

	static function moduleTest()
	{
		script.getParser(HxParser).mode = MODULE;

		runScript('
				package;

				class HelloWorld
				{
					function main(){
						return true;
					}
				}
			', () ->
			{
				return script.variables.get('main')();
			});

		script.superInstance = {"test": () -> trace('testing super instance')};

		runScript('
			package;

			class HelloWorld
			{
				function main(){
					test();

					return true;
				}
			}
		', () -> script.variables.get('main')());

		script.superInstance = {"replace": () -> trace('testing super instance')};

		runScript('
			package;

			using StringTools;

			class HelloWorld
			{
				function main(){
					var a = {
						b:{
							c:{
								text:"hello"
							}
						}
					};
					trace(a.b.c.text.replace("hello","world"));
				}
			}
		');

		script.variables.get('main')();
	}

	static function scriptClassesTest()
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

	public static function resolveModule(name:String):Array<ModuleDecl>
	{
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
	}

	static function fileScriptTest()
	{
		script.getParser(HxParser).mode = DEFAULT;
		runFileScript('PropertyTest.rhx');

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

	static function enumTest()
	{
		script.getParser(HxParser).mode = DEFAULT;

		runScript("test.TestEnum.HELLO", test.TestEnum.HELLO);

		runScript("a = test.TestEnum.RULESCRIPT(1.2)", () -> test.TestEnum.RULESCRIPT(1.2).equals(script.variables['a']));

		var module = script.getParser(HxParser).parseModule(File.getContent('scripts/enumTest/EnumTest.rhx'));
		trace(module);
	}

	static function castTest()
	{
		runScript("
		var a = 1.2;
		cast a;
		cast(a);
		var b = cast(a,Int);
		b;
		", 1);
	}

	static function runScript(code:String, ?value:Dynamic):Dynamic
	{
		// Reset package, for reusing package keyword
		Sys.println('\n[Running code #${++callNum}]: "$code"');

		script.scriptPackage = '';

		final result:Dynamic = script.execute(script.parser.parse(code));

		if (result != null)
			Sys.println('\t\t[Result]: ${Std.string(result)}');

		if (value != null && (Reflect.isFunction(value) ? !value() : result != value))
			throw 'the result($result) does not match the value';

		return result;
	}

	inline static function runFileScript(path:String, ?value:Dynamic)
	{
		runScript(File.getContent('scripts/' + path), value);
	}

	static function onError(e:haxe.Exception):Dynamic
	{
		errorsNum++;
		trace('[ERROR] : ${e.details()}');
		return e.details();
	}
}
