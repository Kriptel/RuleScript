package rulescript.std.hl;

#if hl
import Reflect as HlReflect;

class Reflect
{
	static function hasField(o:Dynamic, field:String):Bool
	{
		return HlReflect.hasField(o, field);
	}

	static function field(o:Dynamic, field:String):Dynamic
	{
		return HlReflect.field(o, field);
	}

	static function setField(o:Dynamic, field:String, value:Dynamic):Void
	{
		HlReflect.setField(o, field, value);
	}

	static function getProperty(o:Dynamic, field:String):Dynamic
	{
		return HlReflect.getProperty(o, field);
	}

	static function setProperty(o:Dynamic, field:String, value:Dynamic):Void
	{
		HlReflect.setProperty(o, field, value);
	}

	static function callMethod(o:Dynamic, func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic
	{
		return Tools.__hl_callMethod(func, args);
	}

	static function fields(o:Dynamic):Array<String>
	{
		return HlReflect.fields(o);
	}

	static function isFunction(f:Dynamic):Bool
	{
		return HlReflect.isFunction(f);
	}

	static function compare<T>(a:T, b:T):Int
	{
		return HlReflect.compare(a, b);
	}

	static function compareMethods(f1:Dynamic, f2:Dynamic):Bool
	{
		return HlReflect.compareMethods(f1, f2);
	}

	static function isObject(v:Dynamic):Bool
	{
		return HlReflect.isObject(v);
	}

	static function isEnumValue(v:Dynamic):Bool
	{
		return HlReflect.isEnumValue(v);
	}

	static function deleteField(o:Dynamic, field:String):Bool
	{
		return HlReflect.deleteField(o, field);
	}

	static function copy(o:Dynamic):Dynamic
	{
		return HlReflect.copy(o);
	}

	static function makeVarArgs(f:Array<Dynamic>->Dynamic):Dynamic
	{
		return HlReflect.makeVarArgs(f);
	}
}
#end
