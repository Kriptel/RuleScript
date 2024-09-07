package;

import TestAbstract;
import rulescript.*;
import test.HelloWorldAbstract;

class Main
{
	public static var script:RuleScript;

	static var callNum:Int;

	public static function main():Void
	{
		script = new RuleScript(null, new HxParser());

		script.getParser(HxParser).allowAll();

		trace('Testing Commands:');

		try
		{
			mathTest();
			packageTest();
			importAndUsingTest();
			stringInterpolationTest();
			testAbstract();
		}
		catch (e)
			trace(e?.details());
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

	public static function testAbstract()
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
	}

	public static function runScript(code:String)
	{
		Sys.println('\n[Running code #${++callNum}]: "$code"\n\n         [Result]: ${script.tryExecute(code)}');
	}
}
