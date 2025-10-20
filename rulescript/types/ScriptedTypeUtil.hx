package rulescript.types;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClassUtil;

class ScriptedTypeUtil
{
	/**
	 * This dynamic method resolves a module using its name.
	 * 
	 * It's currently null, so you'll need to implement your own resolve module method.
	 * 
	 * You'll usually find one in the test folder...
	 * 
	 * @param name The name or path of the module to resolve (e.g "module.path").
	 * @return Array<ModuleDecl>
	 */
	public static dynamic function resolveModule(name:String):Array<ModuleDecl>
	{
		return null;
	}

	@:allow(rulescript.Tools)
	private static var _currentContext:Context;

	/**
	 * Resolves a script defined type by its name.
	 * 
	 * This function checks if the script has already been parsed and cached. If not,
	 * it parses the type path, and resolves the module using the path.
	 * 
	 * @param name The name or path of the module to resolve (e.g "module.path").
	 * @return Dynamic
	 */
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
