package rulescript;

import hscript.Expr;

class RuleScriptInterp extends hscript.Interp
{
	public var scriptPackage:String = '';

	public var imports:Array<Dynamic> = [];
	public var usings:Array<Dynamic> = [];

	override private function resetVariables()
	{
		super.resetVariables();

		scriptPackage = '';

		imports = [];
		usings = [];

		variables.set('Std', Std);
		variables.set('Math', Math);
		variables.set('Type', Type);
		variables.set('Reflect', Reflect);
		variables.set('StringTools', StringTools);

		#if sys
		variables.set('Sys', Sys);
		#end
	}

	override public function expr(expr:Expr):Dynamic
	{
		#if hscriptPos
		curExpr = expr;
		var e:ExprDef = expr.e;
		#else
		var e:Expr = expr;
		#end

		switch (e)
		{
			case EPackage(path):
				if (scriptPackage != '')
					error(ECustom('Unexpected keyword "package"'));

				scriptPackage = path;
			case EImport(path, star, alias, func):
				if (!star)
				{
					var name = alias ?? path.split('.').pop();

					var t:Dynamic = RuleScript.resolveScript(path);

					if (t == null)
						t = Type.resolveClass(path);

					if (t == null)
						t = Type.resolveEnum(path);

					if (t == null)
						error(ECustom('Type not found : $path'));

					if (func != null && t is Class)
						variables.set(func, Reflect.getProperty(t, func));
					else
						variables.set(name, t);
				}
			case EUsing(name):
				var t:Dynamic = Type.resolveClass(name);
				if (t != null)
					usings.push(t);
			default:
				return super.expr(expr);
		}
		return null;
	}

	override function get(o:Dynamic, f:String):Dynamic
	{
		if (Reflect.hasField(o, f))
			return super.get(o, f);

		for (cl in usings)
		{
			if (Reflect.hasField(cl, f))
				return Tools.usingFunction.bind(o, Reflect.getProperty(cl, f), _, _, _, _, _, _, _, _);
		}

		error(ECustom('$o has no field $f'));

		return null;
	}
}
