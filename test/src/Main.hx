package;

import TestAbstract;
import rulescript.*;
import rulescript.parsers.*;
import rulescript.scriptedClass.RuleScriptedClassUtil;
import sys.io.File;
import test.HelloWorldAbstract;
import test.ScriptedClassTest;

class Main
{
	public static var script:RuleScript;

	static var callNum:Int = 0;
	static var errorsNum:Int = 0;

	public static function restTest(hello:String, ...rest:Int) {}

	public static function main():Void
	{
		script = new RuleScript(null, new HxParser());

		script.getParser(HxParser).allowAll();

		trace('Testing Commands:');

		Test.LocalHelloClass.init();
		HelloWorldAbstract.RULESCRIPT;

		try
		{
			mathTest();
			packageTest();
			importAndUsingTest();
			stringInterpolationTest();
			abstractTest();
			moduleTest();
			fileScriptTest();
			scriptClassesTest();
		}
		catch (e)
			trace(e?.details());

		trace('
			Tests: $callNum,
			Errors: $errorsNum
		');
	}

	public static function mathTest()
	{
		runScript('1 + 7');
		runScript('1 - 2');
		runScript('15*2');
		runScript('10 / 2');

		runScript('5 + 5*2');
		runScript('1.1 + 2.53 + 122');
		runScript('(15*2) + (12/2)');
		runScript('2 / (3*5)');

		runScript('1.153');
	}

	public static function packageTest()
	{
		runScript('
            package;

            return "Hello World";
        ');

		runScript('
            package scripts.hello.world;

            return "Hello World";
        ');
	}

	public static function importAndUsingTest()
	{
		runScript('
            import Reflect as AliasReflect;

            var a = {
                "hello":"world"
            };

            return AliasReflect.getProperty(a,"hello");
        ');

		runScript('
            import Reflect.getProperty;

            var a = {
                "hello":"world"
            };

            return getProperty(a,"hello");
        ');

		runScript('
            import Reflect.getProperty as get;

            var a = {
                "hello":"world"
            };

            return get(a,"hello");
        ');

		runScript('
            using Reflect;

            var a = {
                "hello":"world"
            };
            
            return a.getProperty("hello");
        ');
	}

	public static function stringInterpolationTest()
	{
		runScript("
            var a = 'Hello';
        
            return 'RuleScript: $a World';
        ");

		runScript("
            var a = 'World';
        
            return 'RuleScript: Hello $a';
        ");

		runScript("
            var a = {
                a:'RuleScript',
                b: () -> 'Hello',
                c:'World'
            };
        
            return a.a + ' ' + a.b() + ' ' + a.c;
        ");

		runScript("
            var a = {
                a:'RuleScript',
                b: () -> 'Hello',
                c:'World'
            };
        
            return '${a.a}: ${a.b() + \" \" + a.c}';
        ");
	}

	public static function abstractTest()
	{
		runScript('
            import TestAbstract;

            return TestAbstract.helloworld;
        ');

		runScript('
            import test.HelloWorldAbstract;

            return HelloWorldAbstract.rulescriptPrint();
        ');

		runScript('
            import test.HelloWorldAbstract as Hw;

            return Hw.rulescriptPrint();
        ');

		runScript("
            import test.HelloWorldAbstract as Hw;

            return '${Hw.RULESCRIPT}: ${Hw.hello} ${Hw.world}';
        ");

		runScript('
            import Test.LocalHelloClass;

            return LocalHelloClass.hello();
        ');
	}

	public static function moduleTest()
	{
		script.getParser(HxParser).mode = MODULE;

		runScript('
			package;

			class HelloWorld
			{
				function main(){
					trace("hello world");

					var a = {
						b: "rulescript class: hello world"
					}
					trace(Reflect.getProperty(a,"b"));

				}
			}
		');

		script.variables.get('main')();

		script.interp.superInstance = {"test": () -> trace('testing super instance')};

		runScript('
			package;

			class HelloWorld
			{
				function main(){
					test();
				}
			}
		');

		script.variables.get('main')();

		script.interp.superInstance = {"replace": () -> trace('testing super instance')};

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

	public static function scriptClassesTest()
	{
		RuleScriptedClassUtil.registerRuleScriptedClass('scripted', script.getParser(HxParser).parse(File.getContent('scripts/ScriptedClass.rhx')));

		var srcClass = new SrcClassTest(),
			scriptClass = new ScriptedClassTest('scripted');
		trace(srcClass.info());
		trace(scriptClass.info());

		trace(srcClass.argFunction(true, 'hello', 'world'));
		trace(scriptClass.argFunction(true, 'hello', 'world'));
	}

	static function fileScriptTest()
	{
		script.getParser(HxParser).mode = DEFAULT;
		runScript(File.getContent('scripts/PropertyTest.rhx'));

		script.getParser(HxParser).mode = MODULE;
		runScript(File.getContent('scripts/test.rhc'));

		script.variables.get('main')();
	}

	public static function runScript(code:String)
	{
		// Reset package, for reusing package keyword
		script.interp.scriptPackage = '';

		Sys.println('\n[Running code #${++callNum}]: "$code"\n\n         [Result]: ${script.tryExecute(code, onError)}');
	}

	public static function onError(e:haxe.Exception):Dynamic
	{
		errorsNum++;
		return e.details();
	}
}
