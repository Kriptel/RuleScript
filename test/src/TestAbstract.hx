package;

abstract TestAbstract(Test) from Test to Test
{
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
