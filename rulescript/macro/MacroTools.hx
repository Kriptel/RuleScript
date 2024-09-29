package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class MacroTools
{
	/**
	 * Convert Expr function to function
	 */
	public static function toFunction(f:Expr):Function
	{
		return switch (f.expr)
		{
			case EFunction(kind, f):
				f;
			default:
				null;
		}
	}
}

typedef ClassFunctionArg =
{
	var name:String;
	var opt:Bool;
	var t:haxe.macro.Type;
}
#end
