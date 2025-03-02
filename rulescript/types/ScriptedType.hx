package rulescript.types;

interface ScriptedType
{
	var __rulescript_type(get, never):TypeID;
}

enum abstract TypeID(Int)
{
	var OTHER = 0;
	var CLASS = 1;
}
