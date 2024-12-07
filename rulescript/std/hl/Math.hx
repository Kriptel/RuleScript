package rulescript.std.hl;

#if hl
import Math as HlMath;

class Math
{
	public static function sqrt(v:Float):Float
		return HlMath.sqrt(v);

	public static function abs(v:Float):Float
		return HlMath.abs(v);

	public static function floor(v:Float):Int
		return HlMath.floor(v);

	public static function round(v:Float):Int
		return HlMath.round(v);

	public static function ceil(v:Float):Int
		return HlMath.ceil(v);

	public static function isFinite(f:Float):Bool
		return HlMath.isFinite(f);

	public static function isNaN(f:Float):Bool
		return HlMath.isNaN(f);

	public static function ffloor(v:Float):Float
		return HlMath.ffloor(v);

	public static function fround(v:Float):Float
		return HlMath.fround(v);

	public static function fceil(v:Float):Float
		return HlMath.fceil(v);

	public static function cos(v:Float):Float
		return HlMath.cos(v);

	public static function sin(v:Float):Float
		return HlMath.sin(v);

	public static function exp(v:Float):Float
		return HlMath.exp(v);

	public static function log(v:Float):Float
		return HlMath.log(v);

	public static function tan(v:Float):Float
		return HlMath.tan(v);

	public static function atan(v:Float):Float
		return HlMath.atan(v);

	public static function acos(v:Float):Float
		return HlMath.acos(v);

	public static function asin(v:Float):Float
		return HlMath.asin(v);

	public static function pow(v:Float, exp:Float):Float
		return HlMath.pow(v, exp);

	public static function atan2(y:Float, x:Float):Float
		return HlMath.atan2(y, x);

	public static function random():Float
		return HlMath.random();

	public static function min(a:Float, b:Float):Float
		return HlMath.min(a, b);

	public static function max(a:Float, b:Float):Float
		return HlMath.max(a, b);

	public static var PI:Float = HlMath.PI;
	public static var NaN:Float = HlMath.NaN;
	public static var POSITIVE_INFINITY:Float = HlMath.POSITIVE_INFINITY;
	public static var NEGATIVE_INFINITY:Float = HlMath.NEGATIVE_INFINITY;
}
#end
