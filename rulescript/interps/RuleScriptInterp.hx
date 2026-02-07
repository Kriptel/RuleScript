package rulescript.interps;

import hscript.Expr;
import rulescript.RuleScript.IInterp;
import rulescript.Tools.getScriptProp;
import rulescript.interps.interp.RSInterpAccess;
import rulescript.interps.interp.RSInterpConstructor;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.IRuleScriptCustomAccessor;
import rulescript.types.Property;
import rulescript.types.ScriptedAbstract;
import rulescript.types.ScriptedEnum;
import rulescript.types.ScriptedType;
import rulescript.types.ScriptedTypeUtil;
import rulescript.types.ScriptedTypedef;

using rulescript.Tools;

#if hl
import haxe.ds.StringMap;
#end

class RuleScriptInterp extends hscript.Interp implements IInterp
{
	public var scriptName:String;
	public var scriptPackage(default, set):String = '';

	public var access:RuleScriptAccess;

	public var imports:Map<String, Dynamic> = [];
	public var usings:Map<String, Dynamic> = [];

	public var superInstance(default, set):Dynamic;

	public var onMeta:(name:String, args:Array<Expr>, e:Expr) -> Expr;

	public var isSuperCall:Bool = false;

	public var hasErrorHandler:Bool = false;
	public var errorHandler(default, set):haxe.Exception->Void;

	public var context:Context;

	var typePaths:Map<String, Dynamic> = [];

	public function new()
	{
		access ??= new RSInterpAccess(this);
		super();
	}

	override private function resetVariables():Void
	{
		super.resetVariables();

		scriptPackage = '';

		imports = [];
		usings = [];
		typePaths = [];
	}

	override public function posInfos():haxe.PosInfos
	{
		#if hscriptPos
		if (curExpr != null)
			return cast {fileName: scriptName ?? curExpr.origin, lineNumber: curExpr.line};
		#end
		return cast {
			fileName: scriptName ?? "hscript",
			lineNumber: 0
		};
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
		{
			if (superInstance != null)
				v = get(superInstance, id);

			// SHARED VARIABLES
			if (v == null && context != null)
			{
				if (context.staticVariables.exists(id))
					v = context.staticVariables.get(id);
				if (context.publicVariables.exists(id))
					v = context.publicVariables.get(id);
			}

			if (v == null)
				error(EUnknownVariable(id)); // fixes - orbl
		}

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
					if (l.r is Property)
						cast(l.r, Property).value = v;
					else
						l.r = v;
				}
			case EField(e, f):
				v = set(expr(e), f, v);
			case ETypeVarPath(_path):
				final path:Array<String> = _path.copy();
				final f:String = path.pop();

				v = set(resolveTypeOrValue(path), f, v);
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

	override function evalAssignOp(op:String, fop:(Dynamic, Dynamic) -> Dynamic, e1:Expr, e2:Expr):Dynamic
	{
		var v;
		switch (hscript.Tools.expr(e1))
		{
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null)
					setVar(id, v);
				else
				{
					if (l.r is Property)
						cast(l.r, Property).value = v;
					else
						l.r = v;
				}
			case EField(e, f):
				var obj = expr(e);
				v = fop(get(obj, f), expr(e2));
				v = set(expr(e), f, v);
			case ETypeVarPath(_path):
				final path:Array<String> = _path.copy();
				final f:String = path.pop();

				v = fop(expr(e1), expr(e2));
				v = set(resolveTypeOrValue(path), f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				}
				else
				{
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	override function increment(e:Expr, prefix:Bool, delta:Int):Dynamic
	{
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e)
		{
			case EIdent(id):
				var l = locals.get(id);
				var v:Dynamic = (l == null) ? resolve(id) : (l.r is Property ? cast(l.r, Property).value : l.r);

				if (prefix)
				{
					v += delta;
					if (l == null)
						setVar(id, v)
					else
					{
						if (l.r is Property)
							cast(l.r, Property).value = v;
						else
							l.r = v;
					}
				}
				else
				{
					if (l == null)
						setVar(id, v + delta)
					else
					{
						if (l.r is Property)
							cast(l.r, Property).value = v + delta;
						else
							l.r = v + delta;
					}
				}
				return v;
			case EField(e, f):
				var obj = expr(e);
				var v:Dynamic = get(obj, f);
				if (prefix)
				{
					v += delta;
					set(obj, f, v);
				}
				else
					set(obj, f, v + delta);
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					var v = getMapValue(arr, index);
					if (prefix)
					{
						v += delta;
						setMapValue(arr, index, v);
					}
					else
					{
						setMapValue(arr, index, v + delta);
					}
					return v;
				}
				else
				{
					var v = arr[index];
					if (prefix)
					{
						v += delta;
						arr[index] = v;
					}
					else
						arr[index] = v + delta;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}

	override function setVar(name:String, v:Dynamic)
	{
		if (superInstance != null && (superFields.contains(name) || superFields.contains('set_' + name)))
			Reflect.setProperty(superInstance, name, v);
		else if (context != null && context.staticVariables.exists(name))
			context.staticVariables.set(name, v);
		else if (context != null && context.publicVariables.exists(name))
			context.publicVariables.set(name, v);
		else
		{
			var lastValue = variables.get(name);

			if (lastValue is Property)
				cast(lastValue, Property).value = v;
			else
				variables.set(name, v);
		}
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
				scriptPackage = path;
			case EImport(path, star, alias, func):
				if (!star)
				{
					var name = alias ?? path.split('.').pop();

					var t:Dynamic = resolveType(path);

					if (t == null)
						error(ECustom('Type not found : $path'));

					var value = if (func != null && Tools.isClass(t))
					{
						name = alias ?? func;
						Reflect.getProperty(t, func);
					}
					else
						t;

					imports.set(name, value);

					variables.set(name, value);
				}
				else
				{
					for (typeName in Tools.getTypesInPackage(path))
					{
						if (!variables.exists(typeName))
						{
							final type:Dynamic = resolveType(TypePath.createString(path.split('.'), typeName));
							imports.set(typeName, type);
							variables.set(typeName, type);
						}
					}
				}
			case EUsing(path):
				var t:Dynamic = resolveType(path);

				if (t == null)
					error(ECustom('Type not found : $path'));

				usings.set(path, t);
			case ETypeVarPath(path):
				return resolveTypeOrValue(path);
			case EMeta(n, args, e):
				return switch (n)
				{
					case ':contextValue' if (context != null):
						var isFunction:Bool = false;

						final n:Null<String> = switch (Tools.getExpr(e))
						{
							case EFunction(_, _, n):
								isFunction = true;
								n;
							case EProp(n, _), EVar(n, _): n;
							default: null;
						};

						final isStatic:Bool = args.length > 0 && args[0].getExpr().match(EIdent('static'));

						if (isFunction && depth == 0)
						{
							return (isStatic ? context.staticVariables : context.publicVariables)[n] = this.expr(e);
						}
						else if (depth == 0)
						{
							this.expr(e);

							(isStatic ? context.staticVariables : context.publicVariables).set(n, resolve(n));
						}
						else
						{
							this.expr(e);
						}

						null;
					default:
						(onMeta != null) ? onMeta(n, args, e) : exprMeta(n, args, e);
				}

			case EVar(n, _, e, global, _):
				if (global)
				{
					if (context == null || (!context.staticVariables.exists(n) && !context.publicVariables.exists(n)))
						variables.set(n, (e == null) ? null : this.expr(e));
				}
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
				return resolve(id); // wuh
			case ECall(e, params):
				var args = new Array();
				for (p in params)
				{
					if (p.getExpr().match(EUnop('...', true, _)))
						for (arg in cast(this.expr(switch (p.getExpr())
						{
							case EUnop(op, prefix, e): e;
							default: null;
						}), Array<Dynamic>))
							args.push(arg);
					else
						args.push(this.expr(p));
				}

				switch (e.getExpr())
				{
					case EField(e, f):
						var obj = this.expr(e);
						if (obj == null)
							error(EInvalidAccess(f));
						return fcall(obj, f, args);
					default:
						return call(null, this.expr(e), args);
				}
			case EUntyped(e):
				switch (e.getExpr())
				{
					case EIdent('__rulescript__interpType'):
						return 'RuleScriptInterp';

					default:
						return this.expr(e);
				}
			case ECast(e, t):
				switch (t)
				{
					#if hl
					case CTPath(["Int"], _):
						return cast((this.expr(e) : Float), Int);
					#end
					default:
						return this.expr(e);
				}

			case EFunction(params, fexpr, name, _):
				if (name == 'new')
					__constructor = createConstructor(expr, __constructor);

				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt:Bool = false, hasRest:Bool = false, minParams = 0;
				for (p in params)
				{
					if (Tools.isRest(p.t))
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
							if (hasRest && Tools.isRest(p.t))
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
				#if hl
				var f = Tools.__hl_makeVarArgs(f, params.length);
				#else
				var f = Reflect.makeVarArgs(f);
				#end

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
			case ESwitch(e, cases, defaultExpr):
				var val:Dynamic = this.expr(e);
				var match = false;
				for (c in cases)
				{
					var old = declared.length;

					for (v in c.values)
						if (caseMatch(v, e, val))
						{
							match = true;
							break;
						}
						else
							restore(old);

					if (match)
					{
						val = this.expr(c.expr);
						break;
					}

					restore(old);
				}
				if (!match)
					val = defaultExpr == null ? null : this.expr(defaultExpr);
				return val;
			default:
				return super.expr(expr);
		}
		return null;
	}

	function createScriptProperty(n:String, g:String, s:String, type:Null<CType>):Property
	{
		final getter:PropertyAccess = switch (g)
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

		final setter:PropertyAccess = switch (s)
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

		var prop = new Property(getter, setter);

		return prop;
	}

	#if rulescript_is_git_hscript override #end
	function resolveType(path:String):Dynamic
	{
		if (context != null)
			return context.resolveType(path)
		else
			return Tools.resolveType(path);
	}

	function resolveTypeOrValue(path:Array<String>):Dynamic
	{
		final id:String = path[0];

		if ((!locals.exists(id) && !variables.exists(id))
			&& (!superFields.contains(id) && !superFields.contains('get_$id'))
			&& (context == null || !context.staticVariables.exists(id) && !context.publicVariables.exists(id)))
		{
			final typePath:String = path.join('.');

			if (typePaths.exists(typePath))
				return typePaths[typePath];
			else
			{
				final type:Dynamic = resolveType(typePath);
				if (type != null)
					return typePaths[typePath] = type;
				else
				{
					final field = typePath.substring(typePath.lastIndexOf('.') + 1);

					return typePaths[typePath] = get(resolveType(typePath.substring(0, typePath.lastIndexOf('.'))), field);
				}
			}
		}

		var obj:Dynamic = null;
		var l = locals.get(id);
		if (l != null)
			obj = getScriptProp(l.r);

		obj ??= resolve(id);

		var currentField:Int = 0;
		while (path[++currentField] != null)
			obj = get(obj, path[currentField]);

		return obj;
	}

	#if (hscript >= "2.7.0")
	override function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic>
	{
		#if hl
		if (v is StringMap)
			return new haxe.iterators.MapKeyValueIterator(v);
		#end

		return super.makeKeyValueIterator(v);
	}
	#end

	/**
	 * hasField not works for properties
	 * If getProperty object is null, interp tries to get prop from usings
	 */
	override function get(o:Dynamic, f:String):Dynamic
	{
		if (Tools.isEnum(o))
		{
			if (Type.getEnumConstructs(o).contains(f))
			{
				return if (Type.allEnums(o).map(_ -> Std.string(_)).contains(f))
					Type.createEnum(o, f);
				else
					Reflect.makeVarArgs((args:Array<Dynamic>) -> Type.createEnum(o, f, args));
			}
		}

		if (o == this)
		{
			if (variables.exists(f))
				return getScriptProp(variables.get(f));
			else
				o = superInstance;
		}

		if (o is IRuleScriptCustomAccessor)
			return cast(o, IRuleScriptCustomAccessor).getField(f);

		if (o is ScriptedType)
		{
			switch (cast(o, ScriptedType).__rulescript_type)
			{
				case CLASS, ABSTRACT:
					var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
					if (cl.variableExists(f))
						return getScriptProp(cl.getVariable(f));
				case ENUM:
					var en:ScriptedEnum = cast(o, ScriptedEnum);
					return en.getEnumConstructor(f);
				default:
			}
		}

		var prop:Dynamic = super.get(o, f);

		if (prop != null)
			return getScriptProp(prop);

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
				variable is Property ? cast(variable, Property).value = v : variables.set(f, v);
				return v;
			}
			else
				o = superInstance;
		}

		if (o is IRuleScriptCustomAccessor)
			return cast(o, IRuleScriptCustomAccessor).setField(f, v);

		if (o is RuleScriptedClass)
		{
			var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
			if (cl.variableExists(f))
			{
				var o = cl.getVariable(f);
				return o is Property ? cast(o, Property).value = v : cl.setVariable(f, v);
			}
		}

		Reflect.setProperty(o, f, v);
		return v;
	}

	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic
	{
		if (o == superInstance)
			isSuperCall = true;

		if (f == superInstance)
			return call(o, resolve('__super_new'), args);

		#if hl
		final result:Dynamic = Tools.__hl_callMethod(f, args);
		#else
		final result:Dynamic = super.call(o, f, args);
		#end

		isSuperCall = false;

		return result;
	}

	override function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		return call(o, ((o == superInstance
			&& (locals.exists('__super_$f') || variables.exists('__super_$f'))) ? (resolve('__super_$f')) : get(o, f)), args);
	}

	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		var c:Dynamic = Type.resolveClass(cl);

		c ??= ScriptedTypeUtil.resolveScript(cl);
		c ??= resolve(cl);

		if (c is ScriptedTypedef)
		{
			c = cast(c, ScriptedTypedef).resolve(this.execute);
		}

		if (c is ScriptedType)
			switch (cast(c, ScriptedType).__rulescript_type)
			{
				case CLASS:
					return cast(c, ScriptedClass).createInstance(args);
				case ABSTRACT:
					return cast(c, ScriptedAbstract).createInstance(args);
				default:
			}

		#if hl
		return Reflect.isFunction(c) ? Tools.__hl_callMethod(c, args) : Tools.isClass(c) ? Tools.__hl_createInstance(c, args) : c;
		#else
		return Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : Tools.isClass(c) ? Type.createInstance(c, args) : c;
		#end
	}

	function caseMatch(ecase:Expr, evalue:Expr, value:Dynamic):Bool
	{
		if (value is ScriptedEnumInstance || Reflect.isEnumValue(value))
		{
			final isEnumValue:Bool = Reflect.isEnumValue(value);

			final enChecker:EnumHandler = if (!isEnumValue)
			{
				final enInst:ScriptedEnumInstance = cast(value, ScriptedEnumInstance);

				{
					obj: enInst.en,
					hasEnumConstructor: enInst.en.hasEnumConstructor,
					enumHasParams: enInst.en.enumHasParams,
					getEnumConstructor: enInst.en.getEnumConstructor,
					equals: Tools.enumEq.bind(enInst)
				};
			}
			else
			{
				final en:Enum<Dynamic> = cast Type.getEnum(value);
				final enInst:EnumValue = cast value;

				final enConstructs:Array<String> = Type.getEnumConstructs(en);
				final simpleEnums:Array<String> = Type.allEnums(en).map(_ -> Std.string(_));

				{
					obj: en,
					hasEnumConstructor: function(v) return enConstructs.contains(v),
					enumHasParams: function(e) return !simpleEnums.contains(e),
					getEnumConstructor: function(f:String):Dynamic
					{
						return if (simpleEnums.contains(f))
							EnumPattern(en, enConstructs.indexOf(f), null);
						else
							Reflect.makeVarArgs((args:Array<Dynamic>) ->
							{
								EnumPattern(en, enConstructs.indexOf(f), args);
							});
					},
					equals: Tools.enumEq.bind(enInst)
				}
			}

			function enumExpr(e:Expr):Dynamic
			{
				return switch (e.getExpr())
				{
					case EIdent(v) if (enChecker.hasEnumConstructor(v) && !enChecker.enumHasParams(v)):
						enChecker.getEnumConstructor(v);
					case ECall(e, params):
						var isEnumPattern:Bool = false;

						final args:Array<Dynamic> = [
							for (id => param in params)
							{
								switch (param.getExpr())
								{
									case EIdent('_'):
										WildcardPattern;
									case EIdent(id), EVar(id, _) if (!enChecker.hasEnumConstructor(id)):
										VarPattern(value ->
										{
											declared.push({n: id, old: locals.get(id)});
											locals.set(id, {r: value});
										});
									default:
										enumExpr(param);
								}
							}
						];

						switch (e.getExpr())
						{
							case EIdent(v) if (enChecker.hasEnumConstructor(v) && enChecker.enumHasParams(v)):
								call(null, enChecker.getEnumConstructor(v), args);
							default:
								call(null, enumExpr(e), args);
						}
					case EParent(e): enumExpr(e);
					case ECast(e, t): enumExpr(e);
					default: expr(e);
				}
			}

			return enChecker.equals(enumExpr(ecase));
		}

		return expr(ecase) == value;
	}

	function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
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
	public var __constructor:RSInterpConstructor;

	public function createConstructor(expr:Expr, superConstructor:RSInterpConstructor):Dynamic
	{
		return switch (rulescript.Tools.getExpr(expr))
		{
			case EFunction(params, fexpr, name, _):
				final exprs = switch (rulescript.Tools.getExpr(fexpr))
				{
					case EBlock(exprs):
						exprs;
					default:
						null;
				}

				var superID:Int = 0;

				for (expr in exprs)
				{
					switch (rulescript.Tools.getExpr(expr))
					{
						case ECall(e, _) if (rulescript.Tools.getExpr(e).match(EIdent('super'))):
							break;
						default:
							null;
					}
					superID++;
				}

				final preExpr = rulescript.Tools.toExpr(EBlock(exprs.slice(0, superID)));
				final postExpr = rulescript.Tools.toExpr(EBlock(exprs.slice(superID + 1)));

				final superCallArgs:Array<Expr> = superID == exprs.length ? null : switch (rulescript.Tools.getExpr(exprs[superID]))
				{
					case ECall(_, params): params;
					default: null;
				};

				new RSInterpConstructor(superConstructor, this, params, preExpr, superCallArgs, postExpr);
			default:
				null;
		}
	}

	@:noCompletion
	var superFields:Array<String> = [];

	function set_superInstance(value:Dynamic):Dynamic
	{
		if (value != null)
		{
			var o:Class<Dynamic> = Tools.isClass(value) ? cast value : Type.getClass(value);
			superFields = (o != null) ? Type.getInstanceFields(o) : [];
		}

		return superInstance = value;
	}

	@:noCompletion
	inline public function argExpr(e:Expr):Dynamic
	{
		return e != null ? expr(e) : null;
	}

	function set_scriptPackage(value:String):String
	{
		final packages:Array<String> = [];

		var list = '$value.';

		while (StringTools.contains(list, '.'))
		{
			list = list.substr(0, list.lastIndexOf('.'));
			packages.push(list);
		}

		if (packages[0] != '')
			packages.insert(0, '');
		packages.sort((a:String, b:String) -> return (a < b) ? -1 : (a > b) ? 1 : 0);

		for (pack in packages)
		{
			if (RuleScript.defaultImports.exists(pack))
				for (key => value in RuleScript.defaultImports.get(pack))
					variables.set(key, value);
		}

		return scriptPackage = value;
	}
}

private typedef EnumHandler =
{
	var obj:Dynamic;
	var hasEnumConstructor:String->Bool;
	var enumHasParams:String->Bool;
	var getEnumConstructor:String->Dynamic;
	var equals:Dynamic->Bool;
}
