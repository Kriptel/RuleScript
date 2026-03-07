package rulescript.internal.utils;

@:forward
abstract Castable<T:{}>(T) from T to T
{
	inline public function as<C:T>(type:Class<C>):C
	{
		return Std.downcast(this, type);
	}
}
