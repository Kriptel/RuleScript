package tests;

class ImportTest extends Test
{
	override function test()
	{
		// Import class.
		runScript('import Reflect');
		// Import abstract.
		runScript('import haxe.Int64');
		// Import enum.
		runScript('import example.ExampleEnum');

		// Import with alias.
		runScript('
		import Reflect as AliasReflect;
		import Std in AliasStd;
		
		return AliasStd.string(
			AliasReflect.getProperty("Hello World","length")
		);
		', Std.string("Hello World".length));

		// Import function from class.
		runScript('
		import Reflect.getProperty;
		
		return getProperty("Hello World","length");
		', "Hello World".length);
	}
}
