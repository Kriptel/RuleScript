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

	public static function parseTypePath(classPath:String):TypePath
	{
		if (classPath == null || classPath.length == 0)
			return null;

		var path:Array<String> = classPath.split('.');

		var pack:Array<String> = [];

		while (path[0].charAt(0) == path[0].charAt(0).toLowerCase())
			pack.push(path.shift());

		var module:String = null;
		if (path.length > 1)
			module = path.shift();

		return {
			fullPath: classPath,
			name: path[0],
			module: module,
			pack: pack.join('.')
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

typedef TypePath =
{
	var fullPath:String;
	var name:String;
	var ?module:String;
	var pack:String;
};

typedef ClassFunctionArg =
{
	var name:String;
	var opt:Bool;
	var t:haxe.macro.Type;
}
#end
