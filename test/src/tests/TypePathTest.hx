package tests;

class TypePathTest extends Test
{
	override function test()
	{
		runScript('
            sys.FileSystem;
        ', sys.FileSystem);

		var sys = {FileSystem: "hello world"};

		script.variables.set('sys', sys);

		runScript('
            sys.FileSystem;
        ', sys.FileSystem);

		script.variables.remove('sys');
	}
}
