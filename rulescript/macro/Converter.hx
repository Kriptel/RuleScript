package rulescript.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Converter
{
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
		{
			var classPath = MacroTools.parseClassPath(name);
			Compiler.addMetadata('@:build(rulescript.macro.AbstractMacro.build())', '${classPath.pack}.${classPath.name}');
		}

		return null;
	}

	static function parseFile(content:String):Array<String>
	{
		var text:String = content.replace('\r', '').replace(' ', '');
		return text.split('\n');
	}
}
