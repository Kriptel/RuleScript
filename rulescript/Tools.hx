package rulescript;

import haxe.Constraints.Function;
import hscript.Expr;

class Tools
{
	public static function usingFunction(?o:Dynamic, f:Function, ?a1:Dynamic, ?a2:Dynamic, ?a3:Dynamic, ?a4:Dynamic, ?a5:Dynamic, ?a6:Dynamic, ?a7:Dynamic,
			?a8:Dynamic)
	{
		return Reflect.callMethod(o, f, [o, a1, a2, a3, a4, a5, a6, a7, a8]);
	}

	#if hscriptPos
	public static function toExpr(e:ExprDef):Expr
	{
		var _e:Expr = switch (e)
		{
			case EFunction(_, expr):
				expr;
			case EVar(_, _, expr):
				expr;
			default:
				null;
		};
		return
		{
			{
				e: e,
				pmax: _e?.pmax ?? 0,
				pmin: _e?.pmin ?? 0,
				origin: _e?.origin ?? 'rulescript',
				line: _e?.line ?? 0
			}
		}
	}
	#else
	inline public static function toExpr(e:Expr):Expr
		return e;
	#end
}
