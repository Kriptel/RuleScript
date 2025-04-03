package rulescript;

using StringTools;

@:deprecated('rulescript.Abstracts.AbstractDecl was moved to rulescript.types.AbstractDecl')
typedef AbstractDecl = rulescript.types.AbstractDecl;

@:build(rulescript.macro.AbstractMacro.build())
class Abstracts
{
	public static dynamic function resolveAbstract(name:String):Dynamic
	{
		return list[name];
	}
}
