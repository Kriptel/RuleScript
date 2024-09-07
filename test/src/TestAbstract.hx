package;

abstract TestAbstract(Test) from Test to Test
{
	public static inline var helloworld:Int = 1;

	@:from
	static public function fromInt(i:Int):TestAbstract
	{
		return new Test(i);
	}

	@:to
	function toInt():Int
	{
		return this.test;
	}
}
