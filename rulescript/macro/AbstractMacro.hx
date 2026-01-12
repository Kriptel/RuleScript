package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import rulescript.Tools.TypePath;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class AbstractMacro
{
	macro public static function build():Array<Field>
	{
		final defaultFilename:String = 'RuleScriptAbstracts.txt';
		final filename:String = Context.definedValue('rulescript_abstracts_file_path');

		final abstractsList:Array<String> = [];
		final ignoreList:Array<String> = [];

		for (dir in Context.getClassPath())
		{
			for (name in (filename != null ? [defaultFilename, filename] : [defaultFilename]))
				if (FileSystem.exists(dir + name))
					for (abs in parseFile(File.getContent(dir + name)))
					{
						if (abs.startsWith('#') || abs.startsWith('//') || abs.length == 0) // Comment
						{}
						else if (abs.startsWith('-#')) // Ignore
							ignoreList.push(abs);
						else if (!abstractsList.contains(abs)) // Add
							abstractsList.push(abs);
					}
		}

		final list = [
			for (abstractType in abstractsList)
			{
				if (!ignoreList.contains('-#$abstractType'))
					buildAbstract(new TypePath(abstractType));
			}
		];

		final fields = Context.getBuildFields();
		fields.push({
			name: 'list',
			access: [APublic, AStatic],
			kind: FVar(macro :Map<String, Dynamic>, macro $a{list}),
			pos: Context.currentPos()
		});
		return fields;
	}

	static function parseFile(content:String):Array<String>
	{
		final text:String = content.replace('\r', '').replace(' ', '');
		return text.split('\n');
	}

	static function buildAbstract(typePath:TypePath):Expr
	{
		var type = switch (Context.getType(typePath.fullPath))
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

			if (typePath.pack.length > 0 && !ExprTools.getValue(meta.params[1] ?? macro false))
				alias = typePath.pack.join('.') + '.' + alias;
		}

		var value:Expr = {
			expr: EObjectDecl([
				for (field in type.impl.get().statics.get())
					if (!field.meta.has(':ignoreField') && field.name != '_new')
					{
						var isStatic:Bool = true;

						switch (field.expr()?.expr)
						{
							case TFunction(f):
								if (f.args[0] != null && f.args[0].v.name == 'this')
									isStatic = false;
							default:
						}

						if (!field.kind.match(FVar(AccCall, _)) && isStatic)
							{
								field: field.name,
								expr: macro @:privateAccess $p{'${typePath.fullPath}.${field.name}'.split('.')}
							}
					}
			]),
			pos: Context.currentPos()
		}

		return macro $v{alias ?? typePath.fullPath} => $e{value};
	}
}
#end
