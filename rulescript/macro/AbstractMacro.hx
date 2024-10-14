package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import rulescript.macro.MacroTools.ClassPath;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class AbstractMacro
{
	static final targetPackage:String = "rulescript.__abstracts";

	macro public static function build():Array<Field>
	{
		var type = switch (Context.getLocalType())
		{
			case TInst(t, params):
				switch (t.get().kind)
				{
					case KAbstractImpl(a):
						a.get();
					default:
						null;
				}
			case t:
				Context.error('Failed to build non-abstract type', Context.currentPos());
				null;
		}

		var classPath:ClassPath = MacroTools.parseClassPath(type.module.endsWith(type.name) ? type.module : type.module + '.' + type.name);

		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		var isEnum:Bool = type.meta.has(':enum');

		var cl = macro class {};

		cl.meta.push({pos: pos, name: ':keep'});
		cl.meta.push({pos: pos, name: ':noCompletion'});

		var imports = Context.getLocalImports();

		imports.push({
			path: classPath.fullPath.split('.').map(s -> {
				name: s,
				pos: pos
			}),
			mode: INormal
		});

		cl.name = '_' + classPath.name;
		cl.pack = classPath.pack.split('.');

		for (f in fields)
		{
			if (f.access.contains(AStatic) || (isEnum && f.kind.match(FVar(_, _))))
				cl.fields.push({
					name: f.name,
					doc: f.doc,
					access: [APublic, AStatic],
					kind: {
						if (isEnum && (f.kind.match(FVar(_, _))))
							switch (f.kind)
							{
								case FVar(t, e) if (e != null):
									f.kind;
								default:
									FVar(macro :String, macro $v{f.name});
							}
						else
							f.kind;
					},
					pos: f.pos,
					meta: f.meta
				});
		}

		Context.defineModule('$targetPackage.${classPath.pack}._${classPath.name}', [cl], imports);

		return fields;
	}
}
