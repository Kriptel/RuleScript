package tests;

class TypePathTest extends Test
{
	override function test()
	{
		#if sys
		runScript('
            sys.FileSystem;
        ', sys.FileSystem);
		#end

		var sys = {FileSystem: "hello world"};

		script.variables.set('sys', sys);

		runScript('
            sys.FileSystem;
        ', sys.FileSystem);

		script.variables.remove('sys');
	}
}
