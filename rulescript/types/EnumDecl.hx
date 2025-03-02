package rulescript.types;

import hscript.Expr;

typedef EnumDecl =
{
	> hscript.Expr.ModuleType,
	var isExtern:Bool;
	var constructs:Map<String, EnumField>;
	var names:Array<String>;
}

typedef EnumField =
{
	var name:String;
	var type:FieldKind;
	var meta:Metadata;
	var index:Int;
	var params:Array<CType>;
}
