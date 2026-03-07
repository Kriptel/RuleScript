package rulescript.utils;

import hscript.Expr;

class ExprTools
{
	#if hscriptPos
	inline public static function getExpr(e:Expr):ExprDef
	{
		return e.e;
	}
	#else
	inline public static function getExpr(e:Expr):Expr
	{
		return e;
	}
	#end
}
