package rulescript.types;

import hscript.Expr;
import rulescript.Tools.toExpr;
import rulescript.parsers.HxParser;
import rulescript.parsers.Parser;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.scriptedClass.RuleScriptedClassUtil;

class ScriptedTypeUtil
{
	public static dynamic function resolveModule(name:String):Array<ModuleDecl>
	{
		return null;
	}

	static var _parser:Parser =
		{
			var parser = new HxParser();
			parser.allowAll();
			parser.mode = MODULE;
			parser;
		}

	public static dynamic function resolveScript(name:String):Dynamic
	{
		// Check if it has been parsed before.
		final cl = RuleScriptedClassUtil.getClass(name);
		if (cl != null)
			return cl;

		// Parse type path.
		final path:Array<String> = name.split('.');

		final pack:Array<String> = [];

		while (path[0] != null && Tools.startsWithLowerCase(path[0]))
			pack.push(path.shift());

		var moduleName:String = null;

		if (path.length > 1)
			moduleName = path.shift();

		final module = resolveModule((pack.length >= 1 ? pack.join('.') + '.' + (moduleName ?? path[0]) : path[0]));
		// Check file.

		if (module == null)
			return null;

		final typeName = path[0];

		final newModule:Array<ModuleDecl> = []; // packages, imports and usings.

		var typeDecl:Null<ModuleDecl> = null;

		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(_), DUsing(_), DImport(_):
					newModule.push(decl);
				case DClass(c) if (c.name == typeName):
					typeDecl = decl;
				case DAbstract(c) if (c.name == typeName):
					typeDecl = decl;
				case DTypedef(c) if (c.t.match(CTPath(_))):
					typeDecl = decl;
				default:
			}
		}

		newModule.push(typeDecl);

		return switch (typeDecl)
		{
			case DClass(classImpl):
				final scriptedClass = new ScriptedClass({
					name: moduleName ?? path[0],
					path: pack.join('.'),
					decl: newModule
				}, classImpl?.name);

				RuleScriptedClassUtil.registerRuleScriptedClass(scriptedClass.toString(), scriptedClass);

				scriptedClass;
			case DAbstract(abstractImpl):
				new ScriptedAbstract({
					name: moduleName ?? path[0],
					path: pack.join('.'),
					decl: newModule
				}, abstractImpl?.name);

			case DTypedef(c):
				switch (c.t)
				{
					case CTPath(path, params):
						new ScriptedTypedef(toExpr(ETypeVarPath(path.copy())));
					default:
						null;
				}
			default: null;
		}
	}
}
