package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class AbstractMacro
{
	macro public static function build():Array<Field>
	{
		var files:Array<String> = [];

		var filename:String = Context.definedValue('rulescript_abstracts_file_path') ?? 'RuleScriptAbstracts.txt';

		var abstractsList:Array<String> = [];

		for (dir in Context.getClassPath())
			if (FileSystem.exists(dir + filename))
				for (abs in parseFile(File.getContent(dir + filename)))
					if (!abstractsList.contains(abs))
						abstractsList.push(abs);

		var list = [
			for (abstractType in abstractsList)
				macro $v{abstractType} => $e{buildAbstract(MacroTools.parseClassPath(abstractType))}
		];

		var fields = Context.getBuildFields();
		var a = fields.push({
			name: 'list',
			access: [APublic, AStatic],
			kind: FVar(macro :Map<String, Dynamic>, macro $a{list}),
			pos: Context.currentPos()
		});

		return fields;
	}

	static function parseFile(content:String):Array<String>
	{
		var text:String = content.replace('\r', '').replace(' ', '');
		return text.split('\n');
	}

	static function buildAbstract(classPath):Expr
	{
		var type = switch (Context.getType(classPath.fullPath))
		{
			case TAbstract(t, params):
				t.get();
			default:
				Context.error('Failed to build non-abstract type', Context.currentPos());
				null;
		}

		return {
			expr: EObjectDecl([
				for (field in type.impl.get().statics.get())
					if (!field.meta.has(':to') && !field.meta.has(':ignoreField'))
						{
							field: field.name,
							expr: macro @:privateAccess $p{'${classPath.fullPath}.${field.name}'.split('.')}
						}
			]),
			pos: Context.currentPos()
		}
	}
}
#end
