package rulescript.std.hl;

#if hl
import Std as HlStd;

@:haxe.warning("-WDeprecated")
class Std
{
	static function is(v:Dynamic, t:Dynamic):Bool
		return HlStd.is(v, t);

	static function isOfType(v:Dynamic, t:Dynamic):Bool
		return HlStd.isOfType(v, t);

	static function downcast<T:{}, S:T>(value:T, c:Class<S>):S
		return HlStd.downcast(value, c);

	static function instance<T:{}, S:T>(value:T, c:Class<S>):S
		return HlStd.instance(value, c);

	static function string(s:Dynamic):String
		return inline HlStd.string(s);

	static function int(x:Float):Int
		return HlStd.int(x);

	static function parseInt(x:String):Null<Int>
		return inline HlStd.parseInt(x);

	static function parseFloat(x:String):Float
		return inline HlStd.parseFloat(x);

	static function random(x:Int):Int
		return inline HlStd.random(x);
}
#end
