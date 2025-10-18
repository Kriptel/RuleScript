package rulescript.types;

import hscript.Expr;
import rulescript.Tools;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.ScriptedType;

class ScriptedModule implements ScriptedType
{
	public var context:Context;
	public var sharedDecls:Array<ModuleDecl>;

	public var name:String;

	public var types:Map<String, ScriptedType>;

	public var pack:String;

	public function new(typePath:String, module:Array<ModuleDecl>, ?context:Context)
	{
		final path = Tools.parseTypePath(typePath);

		this.name = path.name;
		this.context = context;

		sharedDecls = [];

		types = [];

		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(p):
					if (pack == null)
					{
						pack = p.join('.');

						final filePack:String = path.pack.join('.');
						if (filePack != pack)
							throw '`package${pack != '' ? ' $pack' : ''};` should be `package${filePack != '' ? ' $filePack' : ''};';
					}
					else
						throw 'unexpected package';

					sharedDecls.push(decl);
				case DUsing(_), DImport(_):
					sharedDecls.push(decl);
				case DClass(c):
					types[c.name] = new ScriptedClass(c, this);
				case DAbstract(a):
					types[a.name] = new ScriptedAbstract(a, this);
				case DTypedef(c):
					switch (c.t)
					{
						case CTPath(path, params):
							types[c.name] = new ScriptedTypedef(Tools.toExpr(ETypeVarPath(path.copy())));
						default:
					}
				default:
			}
		}

		for (st in types)
		{
			switch (st.__rulescript_type)
			{
				case CLASS:
					cast(st, ScriptedClass).init();
				case ABSTRACT:
					cast(st, ScriptedAbstract).init();
				default:
			}
		}
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	function get___rulescript_type():TypeID
	{
		return MODULE;
	}
}
