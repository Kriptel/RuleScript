package;

import rulescript.*;

class Main
{
	public static var script:RuleScript;

	static var callNum:Int;

	public static function main():Void
	{
		script = new RuleScript(null, new HxParser());

		var parser = script.getParser(HxParser).parser;

		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

		trace('Testing Commands:');

		try
		{
			mathTest();
			packageTest();
			importAndUsingTest();
			stringInterpolationTest();
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

	public static function runScript(code:String)
	{
		Sys.println('\n[Running code #${++callNum}]: "$code"\n\n         [Result]: ${script.tryExecute(code)}');
	}
}
