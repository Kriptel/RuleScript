package rulescript.types.decl;

import hscript.Expr;

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
