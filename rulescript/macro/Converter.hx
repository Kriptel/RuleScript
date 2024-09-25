package rulescript.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Converter
{
	// Language server shows errors...
	public static macro function init()
	{
		var files:Array<String> = [];

		var filename:String = Context.definedValue('rulescript_abstracts_file_path') ?? 'RuleScriptAbstracts.txt';

		var abstractsList:Array<String> = [];

		for (dir in Context.getClassPath())
			if (FileSystem.exists(dir + filename))
				for (abs in parseFile(File.getContent(dir + filename)))
					if (!abstractsList.contains(abs))
						abstractsList.push(abs);

		for (name in abstractsList)
			Compiler.addMetadata('@:build(rulescript.macro.AbstractMacro.buildAbstract("$name","rulescript.__abstracts"))', name);
		return null;
	}

	static function parseFile(content:String):Array<String>
	{
		var text:String = content.replace('\r', '').replace(' ', '');
		return text.split('\n');
	}
}
