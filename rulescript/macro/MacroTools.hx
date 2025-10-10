package rulescript.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class MacroTools
{
	public static function checkHScript():Void
	{
		final exprType:haxe.macro.Type = Context.getType(#if hscriptPos 'hscript.Expr.ExprDef' #else 'hscript.Expr' #end);

		switch (exprType)
		{
			case TEnum(t, params):
				if (t.get().constructs.exists('EForGen'))
					Compiler.define('rulescript_is_git_hscript');
			default:
		}
	}

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
