package rulescript;

import hscript.Expr.CType;
import hscript.Expr.FieldDecl;
import hscript.Expr.ModuleType;

using StringTools;

typedef AbstractDecl =
{
	> ModuleType,
	var type:Null<CType>;
	var from:Array<CType>;
	var to:Array<CType>;
	var fields:Array<FieldDecl>;
	var isExtern:Bool;
	var isEnum:Bool;
}

@:build(rulescript.macro.AbstractMacro.build())
class Abstracts
{
	public static dynamic function resolveAbstract(name:String):Dynamic
	{
		return list[name];
	}
}
