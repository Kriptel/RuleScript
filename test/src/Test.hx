package;

class Test
{
	public var test:Int = 123456;

	public function new(?test:Int)
	{
		if (test != null)
			this.test = test;
	}
}
