package rulescript.internal.macros;

class DefineMacro
{
	public static macro function get():haxe.macro.Expr.ExprOf<Map<String, String>>
	{
		return macro $v{haxe.macro.Context.getDefines()};
	}
}
