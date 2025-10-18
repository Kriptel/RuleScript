package rulescript.types;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClassUtil;

class ScriptedTypeUtil
{
	public static dynamic function resolveModule(name:String):Array<ModuleDecl>
	{
		return null;
	}

	@:allow(rulescript.Tools)
	private static var _currentContext:Context;

	public static dynamic function resolveScript(name:String):Dynamic
	{
		// Check if it has been parsed before.
		final cl = RuleScriptedClassUtil.getClass(name);
		if (cl != null)
			return cl;

		// Parse type path.
		var path = Tools.parseTypePath(name);

		final module:Array<ModuleDecl> = resolveModule(path.modulePath());

		// Check file.
		if (module == null)
			return null;

		return new ScriptedModule(path.modulePath(), module, _currentContext).types[path.typeName];
	}
}
