package;

import rulescript.RuleScript;

class Main
{
	public static var callNum:Int = 0;
	public static var errorsNum:Int = 0;

	static function main():Void
	{
		print('========\nCurrent target: ' + #if cpp 'cpp' #elseif hl 'hl' #elseif eval 'eval' #else 'other' #end
			+ '\n========');

		new RuleScript();
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
