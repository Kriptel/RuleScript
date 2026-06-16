package rulescript.scriptedClass;

import hscript.Expr;
import rulescript.interps.RuleScriptInterp;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.ScriptedTypeUtil;

using rulescript.Tools;

abstract ScriptedClassType(Dynamic) from ScriptedClass to ScriptedClass to Expr
{
	public var isExpr(get, never):Bool;

	inline function get_isExpr():Bool
	{
		return !(this is ScriptedClass);
	}

	@:deprecated
	@:from inline static function fromExpr(expr:Expr):ScriptedClassType
	{
		return cast expr;
	}
}

class RuleScriptedClassUtil
{
	public static var types:Map<String, ScriptedClassType> = [];

	public static var buildBridge:(typePath:String, superInstance:Dynamic) -> RuleScript;

	public static var autoWrappers:Map<String, Dynamic>;

	public static function registerAutoWrapper(nativeName:String, wrapperClass:Dynamic):Void
	{
		if (autoWrappers == null) 
		{
			autoWrappers = new Map<String, Dynamic>();
		}
		
		autoWrappers.set(nativeName, wrapperClass);
	}

	public static function buildRuleScript(typePath:String, superInstance:Dynamic):RuleScript
	{
		return if (buildBridge != null)
		{
			buildBridge(typePath, superInstance);
		}
		else
		{
			var type:ScriptedClassType = types[typePath] ?? ScriptedTypeUtil.resolveScript(typePath);

			var rulescript = new rulescript.RuleScript();
			rulescript.superInstance = superInstance;
			rulescript.scriptName = typePath;
			if (rulescript.interp is RuleScriptInterp)
				cast(rulescript.interp, RuleScriptInterp).skipNextRestore = true;

			if (type.isExpr)
			{
				rulescript.execute(cast type);

				rulescript;
			}
			else
			{
				var cl:ScriptedClass = cast type;

				buildScriptedClass(cl, rulescript);
			}
			rulescript;
		}
	}

	public static function registerRuleScriptedClass(typePath:String, classType:ScriptedClassType):ScriptedClassType
	{
		return types[typePath] = classType;
	}

	public static function getClass(typePath:String):ScriptedClass
	{
		return cast types[typePath];
	}

	public static function listScriptClasses():Array<String>
	{
		var result:Array<String> = [];
		for (key in types.keys())
		{
			result.push(key);
		}
		return result;
	}

	public static function buildScriptedClass(cl:ScriptedClass, rulescript:RuleScript):Void
	{
		rulescript.access.setVariable('new', () -> {});

		var list = [];

		var currentClass:ScriptedClass = cl;

		while (currentClass != null)
		{
			list.insert(0, currentClass);

			if (currentClass.superClass is ScriptedClass)
				currentClass = currentClass.superClass;
			else
				currentClass = null;
		}

		var exprList:Array<Expr> = [];

		for (cl in list)
		{
			final exprs = Tools.moduleDeclsToExpr(cl.module.sharedDecls,
				{classImpl: cl.impl, isScriptedClass: true, fieldFilter: f -> !f.access.contains(AStatic)});

			final exprs:Array<Expr> = switch (exprs.getExpr())
			{
				case EBlock(exprs): exprs;
				case e: [exprs];
			}

			for (expr in exprs)
				switch (Tools.getExpr(expr))
				{
					default:
						exprList.push(expr);
				}
		}

		rulescript.execute(EBlock(exprList).toExpr());
	}
}
