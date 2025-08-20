package rulescript.types;

import hscript.Expr.ModuleDecl;

typedef ScriptedModule =
{
	var path:String;
	var name:String;
	var decl:Array<ModuleDecl>;
}

interface ScriptedType
{
	var __rulescript_type(get, never):TypeID;
}

enum abstract TypeID(Int)
{
	var OTHER = 0;
	var CLASS = 1;
	var ABSTRACT = 2;
	var TYPEDEF = 3;
}
