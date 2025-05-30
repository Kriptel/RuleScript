package rulescript.types;

using StringTools;

@:haxe.warning("-WDeprecated")
@:build(rulescript.macro.AbstractMacro.build())
class Abstracts
{
	public static dynamic function resolveAbstract(name:String):Dynamic
	{
		return list[name];
	}
}
