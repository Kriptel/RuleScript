package rulescript.internal.utils;

#if macro
import haxe.macro.Expr;

class MacroTools
{
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
#end
