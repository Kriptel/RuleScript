package rulescript;

import hscript.Expr;

class RuleScriptInterp extends hscript.Interp
{
	public var scriptPackage:String = '';

	public var imports:Map<String, Dynamic> = [];
	public var usings:Map<String, Dynamic> = [];

	public var superInstance:Dynamic;

	override private function resetVariables():Void
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
		variables.set('Date', Date);
		variables.set('DateTools', DateTools);

		#if sys
		variables.set('Sys', Sys);
		#end
	}

	override function resolve(id:String):Dynamic
	{
		if (id == 'super' && superInstance != null)
			return superInstance;

		var l:Dynamic = locals.get(id);
		if (l != null)
			return l.r;
		var v:Dynamic = variables.get(id);

		if (v == null && !variables.exists(id))
			v = Reflect.getProperty(superInstance, id) ?? error(EUnknownVariable(id));
		return v;
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

					var t = resolveType(path);

					if (func != null && t is Class)
					{
						var tag:String = alias ?? func;
						imports.set(tag, (variables[tag] = Reflect.getProperty(t, func)));
					}
					else
						variables.set(name, t);
				}
			case EUsing(name):
				var t:Dynamic = resolveType(name);
				if (t != null)
					usings.set(name, t);
			default:
				return super.expr(expr);
		}
		return null;
	}

	function resolveType(path:String):Dynamic
	{
		var t:Dynamic = RuleScript.resolveScript(path);

		t ??= Type.resolveClass(path);

		#if interp
		if (t is Class && Type.getClassFields(t).length == 0)
			t = null;
		#end

		t ??= Abstracts.resolveAbstract(path);

		t ??= Type.resolveEnum(path);

		if (t == null)
			error(ECustom('Type not found : $path'));

		return t;
	}

	/**
	 * hasField not works for properties
	 * If getProperty object is null, interp tries to get prop from usings
	 */
	override function get(o:Dynamic, f:String):Dynamic
	{
		var prop:Dynamic = super.get(o, f);
		if (prop != null)
			return prop;

		for (cl in usings)
		{
			var prop:Dynamic = Reflect.getProperty(cl, f);
			if (prop != null)
				return Tools.usingFunction.bind(o, prop, _, _, _, _, _, _, _, _);
		}

		return null;
	}

	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		var c:Dynamic = Type.resolveClass(cl);
		if (c == null)
			c = resolve(cl);
		return Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : Type.createInstance(c, args);
	}
}
