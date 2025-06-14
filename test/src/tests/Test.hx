package tests;

import rulescript.RuleScript;
import sys.io.File;

class Test
{
	public static var interpNum:Int = 0;
	public static var callNum:Int = 0;
	public static var errorsNum:Int = 0;

	public var script:RuleScript;

	public function new() {}

	public function test():Void {}

	function runScript(code:String, ?value:Dynamic):Dynamic
	{
		// Reset package, for reusing package keyword
		Sys.println('\n[Test #$interpNum/${++callNum}]: "$code"');

		script.scriptPackage = '';

		final result:Dynamic = script.execute(script.parser.parse(code));

		if (result != null)
			Sys.println('\t[Result]: ${Std.string(result)}');

		if (value != null && (Reflect.isFunction(value) ? !value() : result != value))
			throw 'the result($result) does not match the value';

		return result;
	}

	inline function runFileScript(path:String, ?value:Dynamic)
	{
		runScript(File.getContent('scripts/' + path), value);
	}
}
