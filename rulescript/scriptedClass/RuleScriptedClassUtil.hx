package rulescript.scriptedClass;

import hscript.Expr;

class RuleScriptedClassUtil
{
	public static var types:Map<String, Expr> = [];

	public static var buildBridge:(typeName:String, superInstance:Dynamic) -> RuleScript;

	public static function buildRuleScript(typeName:String, superInstance:Dynamic):RuleScript
	{
		return if (buildBridge != null)
		{
			buildBridge(typeName, superInstance);
		}
		else
		{
			var rulescript = new rulescript.RuleScript();
			rulescript.superInstance = superInstance;
			rulescript.interp.skipNextRestore = true;
			rulescript.execute(types[typeName]);
			rulescript;
		}
	}

	public static function registerRuleScriptedClass(typeName:String, e:Expr)
	{
		return types[typeName] = e;
	}
}
