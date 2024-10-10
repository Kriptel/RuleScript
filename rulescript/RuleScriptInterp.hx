package rulescript;

import hscript.Expr;
import rulescript.RuleScriptProperty.Property;
import rulescript.scriptedClass.RuleScriptedClass;

using rulescript.Tools;

class RuleScriptInterp extends hscript.Interp
{
	public var scriptPackage:String = '';

	public var imports:Map<String, Dynamic> = [];
	public var usings:Map<String, Dynamic> = [];

	public var superInstance:Dynamic;

	public var onMeta:(name:String, arr:Array<Expr>, e:Expr) -> Expr;

	public var isSuperCall:Bool = false;

	public var hasErrorHandler:Bool = false;
	public var errorHandler(default, set):haxe.Exception->Dynamic;

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

	override function initOps()
	{
		super.initOps();
		binops.set("??", (e1, e2) -> this.expr(e1) ?? this.expr(e2));
		assignOp("??=", function(v1:Dynamic, v2:Dynamic) return v1 ?? v2);
	}

	override function resolve(id:String):Dynamic
	{
		if (id == 'this')
			return this;

		if (id == 'super' && superInstance != null)
			return superInstance;

		var l:Dynamic = locals.get(id);
		if (l != null)
			return getScriptProp(l.r);
		var v:Dynamic = getScriptProp(variables.get(id));

		if (v == null && !variables.exists(id))
			v = Reflect.getProperty(superInstance, id) ?? error(EUnknownVariable(id));
		return v;
	}

	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);
		switch (hscript.Tools.expr(e1))
		{
			case EIdent(id):
				var l = locals.get(id);
				if (l == null)
					setVar(id, v);
				else
				{
					if (l.r is RuleScriptProperty)
						cast(l.r, RuleScriptProperty).value = v;
					else
						l.r = v;
				}
			case EField(e, f):
				v = set(expr(e), f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					setMapValue(arr, index, v);
				}
				else
				{
					arr[index] = v;
				}

			default:
				error(EInvalidOp("="));
		}
		return v;
	}

	override function setVar(name:String, v:Dynamic)
	{
		var lastValue = variables.get(name);

		if (lastValue is RuleScriptProperty)
			cast(lastValue, RuleScriptProperty).value = v;
		else
			variables.set(name, v);
	}

	inline private function getScriptProp(v:Dynamic):Dynamic
	{
		return v is RuleScriptProperty ? cast(v, RuleScriptProperty).value : v;
	}

	override function exprReturn(e):Dynamic
	{
		if (!inTry && hasErrorHandler)
			try
			{
				return super.exprReturn(e);
			}
			catch (exception:haxe.Exception)
			{
				errorHandler(exception);
			}
		else
			return super.exprReturn(e);
		return null;
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
			case EMeta(name, args, e) if (onMeta != null):
				return onMeta(name, args, e);
			case EVar(n, _, e, global):
				if (global)
					variables.set(n, (e == null) ? null : this.expr(e));
				else
				{
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: (e == null) ? null : this.expr(e)});
				}
				return null;
			case EProp(n, g, s, type, e, global):
				var prop = createScriptProperty(n, g, s, type);
				if (global)
					variables.set(n, prop);
				else
				{
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: prop});
				}
				if (e != null)
					prop._lazyValue = () -> this.expr(e);
				return null;
			case EIdent(id):
				var l = locals.get(id);
				if (l != null)
					return getScriptProp(l.r);
				return resolve(id);
			case EFor(key, it, e, value):
				if (value == null)
					forLoop(key, it, e);
				else
					forLoopKeyValue(key, value, it, e);
				return null;
			case EFunction(params, fexpr, name, _):
				if (name == 'new')
					__constructor = expr;

				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt:Bool = false, hasRest:Bool = false, minParams = 0;
				for (p in params)
				{
					if (p.t.match(CTPath(["haxe", "Rest"], _)))
					{
						if (params.indexOf(p) == params.length - 1)
							hasRest = true;
						else
							error(ECustom("Rest should only be used for the last function argument"));
					}

					if (p.opt)
						hasOpt = true;
					else
						minParams++;
				}

				var f = function(args:Array<Dynamic>)
				{
					if (((args == null) ? 0 : args.length) != params.length)
					{
						if (args.length < minParams && (!hasRest && args.length + 1 < minParams))
						{
							var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
							if (name != null)
								str += " for function '" + name + "'";
							error(ECustom(str));
						}
						// make sure mandatory args are forced
						var args2 = [];
						var extraParams = args.length - minParams;
						var pos = 0;
						for (p in params)
						{
							if (hasRest && p.t.match(CTPath(["haxe", "Rest"], _)))
								args2.push([for (i in pos...args.length) args[i]]);
							else
							{
								if (p.opt)
								{
									if (extraParams > 0)
									{
										args2.push(args[pos++]);
										extraParams--;
									}
									else
										args2.push(null);
								}
								else
									args2.push(args[pos++]);
							}
						}
						args = args2;
					}
					else if (hasRest)
						args.push([args.pop()]);

					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i]});
					var r = null;
					var oldDecl = declared.length;
					if (inTry)
						try
						{
							r = me.exprReturn(fexpr);
						}
						catch (e:Dynamic)
						{
							restore(oldDecl);
							me.locals = old;
							me.depth = depth;
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					else
						r = me.exprReturn(fexpr);
					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};
				var f = Reflect.makeVarArgs(f);
				if (name != null)
				{
					if (depth == 0)
					{
						// global function
						variables.set(name, f);
					}
					else
					{
						// function-in-function is a local function
						declared.push({n: name, old: locals.get(name)});
						var ref = {r: f};
						locals.set(name, ref);
						capturedLocals.set(name, ref); // allow self-recursion
					}
				}
				return f;

			default:
				return super.expr(expr);
		}
		return null;
	}

	function createScriptProperty(n:String, g:String, s:String, type:Null<CType>)
	{
		var getter:Property = switch (g)
		{
			case 'default':
				DEFAULT;
			case 'get':
				GET(() -> exprReturn(ECall(EIdent('get_$n').toExpr(), []).toExpr()));
			case 'null':
				NULL;
			case 'dynamic':
				DYNAMIC((?v:Dynamic) -> exprReturn(ECall(EIdent('get_$n').toExpr(), []).toExpr()));
			case 'never':
				NEVER;
			default:
				error(ECustom('$n: Custom property accessor is no longer supported, please use `get`'));
		}

		var setter:Property = switch (s)
		{
			case 'default':
				DEFAULT;
			case 'set':
				SET(v -> call(null, resolve('set_$n'), [v]));
			case 'null':
				NULL;
			case 'dynamic':
				DYNAMIC((?v:Dynamic) -> call(null, resolve('set_$n'), [v]));
			case 'never':
				NEVER;
			default:
				error(ECustom('$n: Custom property accessor is no longer supported, please use `set`'));
		}

		var prop = new RuleScriptProperty(getter, setter);

		return prop;
	}

	function resolveType(path:String):Dynamic
	{
		var t:Dynamic = RuleScript.resolveScript(path);

		if (t != null)
			return t;

		var shortPath:String = null;

		if (StringTools.contains(path, '.'))
		{
			var _shortPath = path.split('.');
			if (_shortPath.length > 1)
			{
				_shortPath.remove(_shortPath[_shortPath.length - 2]);
				shortPath = _shortPath.join('.');
			}
		}

		t ??= Type.resolveClass(path);

		#if interp t = Tools.isEmptyClass(t) ? null : t; #end

		if (t == null && shortPath != null)
		{
			t = Type.resolveClass(shortPath);

			#if interp t = Tools.isEmptyClass(t) ? null : t; #end
		}

		t ??= Abstracts.resolveAbstract(path);

		#if interp t = Tools.isEmptyClass(t) ? null : t; #end

		t ??= Type.resolveEnum(path);

		if (t == null)
			error(ECustom('Type not found : $path'));

		return t;
	}

	function makeKeyValueIterator(v:Dynamic)
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();
		#else
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();
		// try v = v?.iterator() catch( e : Dynamic ) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	function forLoopKeyValue(key:String, value:String, it:Expr, e:Expr)
	{
		var old = declared.length;

		declared.push({n: key, old: locals.get(key)});
		declared.push({n: value, old: locals.get(value)});

		var it:{hasNext:() -> Bool, next:() -> Dynamic} = makeKeyValueIterator(expr(it));
		while (it.hasNext())
		{
			var itNext = it.next();
			locals.set(key, {r: itNext.key});
			locals.set(value, {r: itNext.value});
			if (!loopRun(() -> expr(e)))
				break;
		}
		restore(old);
	}

	/**
	 * hasField not works for properties
	 * If getProperty object is null, interp tries to get prop from usings
	 */
	override function get(o:Dynamic, f:String):Dynamic
	{
		if (o == this)
		{
			if (variables.exists(f))
				return getScriptProp(variables.get(f));
			else
				o = superInstance;
		}

		var prop:Dynamic = super.get(o, f);

		if (prop != null)
			return getScriptProp(prop);

		if (o is RuleScriptedClass)
		{
			var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
			if (cl.variableExists(f))
				return getScriptProp(cl.getVariable(f));
		}

		for (cl in usings)
		{
			var prop:Dynamic = Reflect.getProperty(cl, f);
			if (prop != null)
				return Tools.usingFunction.bind(o, prop, _, _, _, _, _, _, _, _);
		}

		return null;
	}

	override function set(o:Dynamic, f:String, v:Dynamic):Dynamic
	{
		if (o == null)
			error(EInvalidAccess(f));

		if (o == this)
		{
			if (variables.exists(f))
			{
				var variable:Dynamic = variables.get(f);
				variable is RuleScriptProperty ? cast(variable, RuleScriptProperty).value = v : variables.set(f, v);
				return v;
			}
			else
				o = superInstance;
		}

		if (o is RuleScriptedClass)
		{
			var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
			if (cl.variableExists(f))
			{
				var o = cl.getVariable(f);
				return o is RuleScriptProperty ? cast(o, RuleScriptProperty).value = v : cl.setVariable(f, v);
			}
		}

		Reflect.setProperty(o, f, v);
		return v;
	}

	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic
	{
		if (o == superInstance)
			isSuperCall = true;

		var result:Dynamic = super.call(o, f, args);

		isSuperCall = false;

		return result;
	}

	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		var c:Dynamic = Type.resolveClass(cl);

		c ??= RuleScript.resolveScript(cl);
		c ??= resolve(cl);

		return Reflect.Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : c is Class ? Type.createInstance(c, args) : c;
	}

	function set_errorHandler(v:haxe.Exception->Dynamic):haxe.Exception->Dynamic
	{
		hasErrorHandler = v != null;

		return errorHandler = v;
	}

	@:noCompletion
	public var skipNextRestore:Bool = false;

	override function restore(old:Int)
	{
		if (skipNextRestore)
			skipNextRestore = false;
		else
			super.restore(old);
	}

	// for RuleScriptedClass
	@:noCompletion
	public var __constructor:Expr;

	@:noCompletion
	public function makeSuperFunction(params:Array<Argument>, args:Array<Dynamic>)
	{
		var capturedLocals = duplicate(locals);
		var me = this;
		var hasOpt:Bool = false, hasRest:Bool = false, minParams = 0;
		for (p in params)
		{
			if (p.t.match(CTPath(["haxe", "Rest"], _)))
			{
				if (params.indexOf(p) == params.length - 1)
					hasRest = true;
				else
					error(ECustom("Rest should only be used for the last function argument"));
			}

			if (p.opt)
				hasOpt = true;
			else
				minParams++;
		}

		if (((args == null) ? 0 : args.length) != params.length)
		{
			if (args.length < minParams && (!hasRest && args.length + 1 < minParams))
			{
				var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams + " for function 'new'";
				error(ECustom(str));
			}

			var args2 = [];
			var extraParams = args.length - minParams;
			var pos = 0;
			for (p in params)
			{
				if (hasRest && p.t.match(CTPath(["haxe", "Rest"], _)))
					args2.push([for (i in pos...args.length) args[i]]);
				else
				{
					if (p.opt)
					{
						if (extraParams > 0)
						{
							args2.push(args[pos++]);
							extraParams--;
						}
						else
							args2.push(null);
					}
					else
						args2.push(args[pos++]);
				}
			}
			args = args2;
		}
		else if (hasRest)
			args.push([args.pop()]);

		var old = me.locals, depth = me.depth;
		me.depth++;
		me.locals = me.duplicate(capturedLocals);
		for (i in 0...params.length)
			me.locals.set(params[i].name, {r: args[i]});
		var r:Dynamic = null;
		var oldDecl = declared.length;

		return {
			f: (e:Expr) -> me.exprReturn(e),
			finish: () ->
			{
				restore(oldDecl);
				me.locals = old;
				me.depth = depth;
			}
		};
	}

	@:noCompletion
	inline public function argExpr(e:Expr):Dynamic
	{
		return e != null ? expr(e) : null;
	}
}
