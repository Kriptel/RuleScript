package rulescript.types;

class Typedefs
{
	private static var typedefs:Map<String, Dynamic> = [
		'haxe.Int32' => Int,
		'rulescript.BytecodeInterp' => rulescript.interps.BytecodeInterp,
		'rulescript.Parser' => rulescript.parsers.Parser,
		'rulescript.HxParser' => rulescript.parsers.HxParser
	];

	/**
	 * @param typePath	(example: `hello.world.A`, `hello.world.A.B`)
	 * @param type 
	 */
	inline public static function register(typePath:String, type:Dynamic)
	{
		return typedefs[typePath] = type;
	}

	inline public static function resolveTypedef(typePath:String):Dynamic
	{
		return typedefs[typePath];
	}

	inline public static function getAll():Map<String, Dynamic>
	{
		return typedefs;
	}
}
