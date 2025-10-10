package rulescript.types;

interface ScriptedType
{
	var __rulescript_type(get, never):TypeID;
}

enum abstract TypeID(Int)
{
	var OTHER = 0;
	var MODULE = 1;
	var CLASS = 2;
	var ABSTRACT = 3;
	var TYPEDEF = 4;
}
