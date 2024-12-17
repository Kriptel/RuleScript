package;

import hscript.Expr.ModuleDecl;
import hscript.Printer;
import rulescript.RuleScript;
import rulescript.Tools;
import rulescript.parsers.HxParser;
import rulescript.scriptedClass.RuleScriptedClassUtil;
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

		script = new RuleScript(new HxParser());

		script.scriptName = ' [[RULESCRIPT TEST]]';

		script.getParser(HxParser).allowAll();

		script.errorHandler = onError;

		try
		{
			mathTest();
			packageTest();
			importAndUsingTest();
			stringInterpolationTest();
			abstractTest();
			typePathTest();
			moduleTest();
			scriptClassesTest();
			fileScriptTest();
		}
		catch (e)
			trace(e?.details());

		Sys.println('\n\tTests:$callNum,\n\tErrors: $errorsNum');
	}

	static function mathTest()
	{
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
		runScript('package', () -> script.interp.scriptPackage == '');

		runScript('package scripts.hello.world', () -> script.interp.scriptPackage == 'scripts.hello.world');
	}

	static function importAndUsingTest()
	{
		script.variables.set('a', {hello: 'world'});

		runScript('
            import Reflect as AliasReflect;

            AliasReflect.getProperty(a,"hello");
        ', 'world');

		runScript('
            import Reflect.getProperty;

            getProperty(a,"hello");
        ', 'world');

		runScript('
            import Reflect.getProperty as get;

            get(a,"hello");
        ', 'world');

		runScript('
            using Reflect;
            
            a.getProperty("hello");
        ', 'world');

		script.variables.remove('a');
	}

	static function stringInterpolationTest()
	{
		script.variables.set('a', {hello: 'World'});

		runScript("  'RuleScript: $a World'  ");

		runScript("  'RuleScript: Hello $a'  ");

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

		script.variables.remove('a');
	}

	static function abstractTest()
	{
		runScript('
            import test.TestAbstract;

            TestAbstract.helloworld;
        ', TestAbstract.helloworld);

		runScript('
            test.HelloWorldAbstract.rulescriptPrint();
        ', HelloWorldAbstract.rulescriptPrint());
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
					trace("hello world");

					var a = {
						b: "rulescript class: hello world"
					}
					trace(Reflect.getProperty(a,"b"));

				}
			}
		');

		script.variables.get('main')();

		script.superInstance = {"test": () -> trace('testing super instance')};

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

		RuleScriptedClassUtil.registerRuleScriptedClass('ScriptedClass', script.getParser(HxParser).parse(File.getContent('scripts/haxe/ScriptedClass.rhx')));
		RuleScriptedClassUtil.registerRuleScriptedClass('ScriptedClassStrict',
			script.getParser(HxParser).parse(File.getContent('scripts/haxe/ScriptedClassStrict.rhx')));

		// Custom constructor can't have extra args

		new ScriptedClassTestStrict('ScriptedClassStrict', 'Script');

		var srcClass = new SrcClassTest<Hello<Int>, Int>('Src'),
			scriptClass = new ScriptedClassTest('ScriptedClass', [4, 'Script']);
		trace(srcClass.info());
		trace(scriptClass.info());

		trace(srcClass.argFunction(true, 'hello', 'world'));
		trace(scriptClass.argFunction(true, 'hello', 'world'));

		trace(srcClass.string(new Hello<Int>(12)));
		trace(scriptClass.string(new Hello<String>('hello')));

		trace(srcClass.stringArray([new Hello<Int>(12)]));
		trace(scriptClass.stringArray([new Hello<String>('hello')]));

		if (scriptClass.variableExists('scriptFunction'))
			trace(scriptClass.getVariable('scriptFunction')());

		RuleScriptedClassUtil.buildBridge = customBuildRuleScript;

		Sys.println('\n[Custom RuleScriptedClass Builder]\n');

		var srcClass = new SrcClassTest<Hello<Int>, Int>('Src'),
			scriptClass = new ScriptedClassTest('ScriptedClass', [1, 'Script']);
		trace(srcClass.info());
		trace(scriptClass.info());
	}

	public static function customBuildRuleScript(typeName:String, superInstance:Dynamic):RuleScript
	{
		var rulescript = new rulescript.RuleScript();
		rulescript.getParser(HxParser).allowAll();
		rulescript.getParser(HxParser).mode = MODULE;

		rulescript.superInstance = superInstance;
		rulescript.interp.skipNextRestore = true;
		rulescript.execute(File.getContent('scripts/haxe/${typeName.replace('.', '/')}.rhx'));
		return rulescript;
	}

	static function fileScriptTest()
	{
		script.getParser(HxParser).mode = DEFAULT;
		runFileScript('haxe/PropertyTest.rhx');

		runFileScript('haxe/StringInterpolation.rhx');

		script.getParser(HxParser).mode = MODULE;
		runFileScript('haxe/test.rhx');

		script.variables.get('main')();

		var old = RuleScript.resolveScript;

		RuleScript.resolveScript = function(name:String):Dynamic
		{
			if (!FileSystem.exists('scripts/haxe/${name.replace('.', '/')}.rhx'))
				return null;

			var parser = new HxParser();
			parser.allowAll();
			parser.mode = MODULE;

			var module:Array<ModuleDecl> = parser.parseModule(File.getContent('scripts/haxe/${name.replace('.', '/')}.rhx'));

			var newModule:Array<ModuleDecl> = [];

			var extend:String = null;
			for (decl in module)
			{
				switch (decl)
				{
					case DPackage(_), DUsing(_), DImport(_):
						newModule.push(decl);
					case DClass(c):
						if (name.split('.').pop() == c.name)
						{
							newModule.push(decl);
							if (c.extend != null)
							{
								extend = new Printer().typeToString(c.extend);
							}
						}
					default:
				}
			}

			var obj:Dynamic = null;

			if (extend == null)
			{
				var script = new RuleScript();
				script.execute(Tools.moduleDeclsToExpr(newModule));

				obj = {};
				for (key => value in script.variables)
					Reflect.setField(obj, key, value);
			}
			else
			{
				var cl = Type.resolveClass(extend);
				var f = function(args:Array<Dynamic>)
				{
					return Type.createInstance(cl, [name, args]);
				}

				obj = Reflect.makeVarArgs(f);
			}

			return obj;
		}

		runFileScript('haxe/importTest/ScriptImportTest.rhx');

		script.variables.get('main')();

		RuleScript.resolveScript = old;
	}

	static function runScript(code:String, ?value:Dynamic)
	{
		// Reset package, for reusing package keyword
		Sys.println('\n[Running code #${++callNum}]: "$code"');

		script.interp.scriptPackage = '';

		var result = script.tryExecute(script.parser.parse(code));

		if (result != null)
			Sys.println('\t\t[Result]: ${Std.string(result)}');

		if (value != null && (Reflect.isFunction(value) ? !value() : result != value))
			throw 'the result does not match the value';
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
