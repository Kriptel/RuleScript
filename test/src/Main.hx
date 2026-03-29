package;

import rulescript.Context;
import rulescript.RuleScript;
import tests.*;

class Main
{
	public static var callNum:Int = 0;
	public static var errorsNum:Int = 0;

	static function main():Void
	{
		print('========\nCurrent target: ' + #if cpp 'cpp' #elseif hl 'hl' #elseif eval 'eval' #else 'other' #end
			+ '\n========');

		final tests:Array<Test> = [new MathTest(), new PreprocessTest()];

		final script = new RuleScript();

		for (test in tests)
		{
			test.script = script;
			test.test();
		}
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
