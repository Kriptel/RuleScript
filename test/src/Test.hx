package;

class Test
{
	public var test:Int = 123456;

	public function new(?test:Int)
	{
		if (test != null)
			this.test = test;

		LocalHelloClass.init();
	}
}

class LocalHelloClass
{
	public static function init() {}

	public static function hello()
	{
		return 'world';
	}
}
