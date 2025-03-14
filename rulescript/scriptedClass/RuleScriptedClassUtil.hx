package rulescript.scriptedClass;

import hscript.Expr;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedInstance;

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

		var lastNew:Expr = null, exprList:Array<Expr> = [];

		for (cl in list)
		{
			final exprs = Tools.moduleDeclsToExpr(cl.module.decl, {isScriptedClass: true, fieldFilter: f -> !f.access.contains(AStatic)});

			final exprs:Array<Expr> = switch (exprs.getExpr())
			{
				case EBlock(exprs): exprs;
				case e: [exprs];
			}

			for (expr in exprs)
				switch (Tools.getExpr(expr))
				{
					case EFunction(args, e, name, ret) if (name == 'new'):
						if (lastNew != null)
						{
							var exprs = switch (e.getExpr())
							{
								case EBlock(e): e.copy();
								default: [e];
							}

							var superID = 0;

							for (expr in exprs)
							{
								switch (expr.getExpr())
								{
									case ECall(e, _) if (e.getExpr().match(EIdent('super'))):
										break;
									default:
								}
								superID++;
							}

							switch (lastNew.getExpr())
							{
								case EFunction(args, e, name, ret):
									final superExpr = exprs[superID];

									final superArgs = switch (superExpr.getExpr())
									{
										case ECall(e, params):
											params;
										default: null;
									}

									exprs.remove(superExpr);

									exprs.insert(superID,
										EUntyped(ECall(EFunction(args, EBlock([]).toExpr(), '__super_start').toExpr(), superArgs).toExpr()).toExpr());

									switch (e.getExpr())
									{
										case EBlock(_exprs):
											for (expr in _exprs)
												exprs.insert(++superID, expr);
										default:
											exprs.insert(++superID, e);
									}

									exprs.insert(++superID, EUntyped(ECall(EIdent('__super_end').toExpr(), []).toExpr()).toExpr());
								default:
							}

							lastNew = Tools.toExpr(EFunction(args, Tools.toExpr(EBlock(exprs)), name, ret));
						}
						else
							lastNew = expr;
					default:
						exprList.push(expr);
				}
		}
		exprList.push(lastNew);

		rulescript.execute(EBlock(exprList).toExpr());
	}
}
