package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import rulescript.macro.MacroTools.ClassPath;
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
				buildAbstract(MacroTools.parseClassPath(abstractType))
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

	static function buildAbstract(classPath:ClassPath):Expr
	{
		var type = switch (Context.getType(classPath.fullPath))
		{
			case TAbstract(t, params):
				t.get();
			default:
				Context.error('Failed to build non-abstract type', Context.currentPos());
				null;
		}

		var alias:String = null;

		if (type.meta.has(':alias'))
		{
			var meta = [
				for (meta in type.meta.get())
					if (meta.name == ':alias')
						meta
			][0];

			alias = ExprTools.getValue(meta.params[0]);

			if (!ExprTools.getValue(meta.params[1] ?? macro false))
				alias = '${classPath.pack}.${alias}';
		}

		var value:Expr = {
			expr: EObjectDecl([
				for (field in type.impl.get().statics.get())
					if (!field.meta.has(':ignoreField'))
					{
						var isStatic:Bool = true;

						switch (field.expr().expr)
						{
							case TFunction(f):
								if (f.args[0] != null && f.args[0].v.name == 'this')
									isStatic = false;
							default:
						}

						if (isStatic)
							{
								field: field.name,
								expr: macro @:privateAccess $p{'${classPath.fullPath}.${field.name}'.split('.')}
							}
					}
			]),
			pos: Context.currentPos()
		}

		return macro $v{alias ?? classPath.fullPath} => $e{value};
	}
}
#end
