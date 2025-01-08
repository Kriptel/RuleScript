package rulescript.scriptedClass;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedInstance;

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

	public static function buildRuleScript(typePath:String, superInstance:Dynamic):RuleScript
	{
		return if (buildBridge != null)
		{
			buildBridge(typePath, superInstance);
		}
		else
		{
			var type:ScriptedClassType = types[typePath] ?? RuleScript.resolveScript(typePath);

			var rulescript = new rulescript.RuleScript();
			rulescript.superInstance = superInstance;
			rulescript.interp.skipNextRestore = true;

			if (type.isExpr)
			{
				rulescript.execute(cast type);

				rulescript;
			}
			else
			{
				var cl:ScriptedClass = cast type;

				rulescript.execute(Tools.toExpr(EBlock([
					Tools.moduleDeclsToExpr(cl.module.decl, {
						isScriptedClass: false,
						fieldFilter: f -> !f.access.contains(AStatic)
					})
				])));
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
}
