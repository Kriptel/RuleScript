package rulescript;

import haxe.Constraints.Function;
import hscript.Expr;
import hscript.Printer;

#if hl
@:build(rulescript.macro.CallMethodMacro.build())
#end
class Tools
{
	static var _printer:Printer = new Printer();

	inline public static function exprToString(expr:Expr):String
	{
		return _printer.exprToString(expr);
	}

	inline public static function typeToString(type:CType):String
	{
		return _printer.typeToString(type);
	}

	@:noCompletion public static function usingFunction(?o:Dynamic, f:Function, ?a1:Dynamic, ?a2:Dynamic, ?a3:Dynamic, ?a4:Dynamic, ?a5:Dynamic, ?a6:Dynamic,
			?a7:Dynamic, ?a8:Dynamic)
	{
		#if interp
		var args:Array<Dynamic> = [o, a1, a2, a3, a4, a5, a6, a7, a8];
		var i:Int = 8;

		while (i >= 0)
		{
			if (args[i] == null)
				args.pop();
			else
				break;
			i--;
		}
		return Reflect.callMethod(o, f, args);
		#elseif hl
		return __hl_callMethod(f, [o, a1, a2, a3, a4, a5, a6, a7, a8]);
		#else
		return Reflect.callMethod(o, f, [o, a1, a2, a3, a4, a5, a6, a7, a8]);
		#end
	}

	#if hscriptPos
	public static function toExpr(e:ExprDef):Expr
	{
		var _e:Expr = switch (e)
		{
			case EFunction(_, expr):
				expr;
			case EVar(_, _, expr):
				expr;
			default:
				null;
		};
		return
		{
			{
				e: e,
				pmax: _e?.pmax ?? 0,
				pmin: _e?.pmin ?? 0,
				origin: _e?.origin ?? 'rulescript',
				line: _e?.line ?? 0
			}
		}
	}
	#else
	inline public static function toExpr(e:Expr):Expr
		return e;
	#end

	#if hscriptPos
	inline public static function getExpr(e:Expr):ExprDef
		return e.e;
	#else
	inline public static function getExpr(e:Expr):Expr
		return e;
	#end

	inline public static function isClass(t:Dynamic):Bool
	{
		#if cpp
		return Type.resolveClass(Type.getClassName(t)) != null;
		#else
		return t is Class;
		#end
	}

	inline public static function isEnum(t:Dynamic):Bool
	{
		#if cpp
		return Type.typeof(t).match(TEnum(_));
		#else
		return t is Enum;
		#end
	}

	inline public static function startsWithLowerCase(s:String):Bool
		return s.charAt(0) == s.charAt(0).toLowerCase();

	inline public static function startsWithUpperCase(s:String):Bool
		return s.charAt(0) == s.charAt(0).toUpperCase();

	inline public static function isEmptyClass(cl:Class<Dynamic>):Bool
	{
		#if interp
		// Because interp returns an empty class instead of null
		return (cl is Class) ? Type.getClassFields(cl).length == 0 : false;
		#else
		return false;
		#end
	}

	public static function moduleDeclsToExpr(moduleDecls:Array<ModuleDecl>, ?parameters:{?isScriptedClass:Bool, ?fieldFilter:FieldDecl->Bool}):Expr
	{
		var fields:Array<Expr> = [];

		#if hscriptPos
		var pushExpr = (e:ExprDef) -> fields.push(toExpr(e));
		#else
		var pushExpr = (e:Expr) -> fields.push(e);
		#end

		for (moduleDecl in moduleDecls)
			switch (moduleDecl)
			{
				case DPackage(path):
					pushExpr(EPackage(path.join('.')));
				case DImport(path, star, alias, func):
					pushExpr(EImport(path.join('.'), star, alias, func));
				case DUsing(path):
					pushExpr(EUsing(path));
				case DClass(c):
					c.fields.sort((f1:FieldDecl, f2:FieldDecl) ->
					{
						return switch [f1.kind.match(KVar(_)), f2.kind.match(KVar(_))]
						{
							case [true, true], [false, false]: 0;
							case [true, false]: -1;
							case [false, true]: 1;
						};
					});

					for (field in c.fields)
					{
						if (parameters?.fieldFilter(field) ?? true)
							switch (field.kind)
							{
								case KFunction(f):
									if (parameters?.isScriptedClass
										&& (field.access.contains(AOverride) || (field.name == 'new' && c.extend != null)))
										pushExpr(EVar('__super_${field.name}', null, toExpr(EIdent(field.name)), false));

									pushExpr(EFunction(f.args, f.expr, field.name, f.ret));
								case KVar(v):
									if (v.get == null && v.set == null)
									{
										pushExpr(EVar(field.name, v.type, v.expr, field.access.contains(APublic), field.access.contains(AFinal)));
									}
									else
									{
										pushExpr(EProp(field.name, v.get, v.set, v.type, v.expr, field.access.contains(APublic)));
									}
							}
					}

				case DTypedef(c):

				default:
			}

		#if hscriptPos
		return {
			e: EBlock(fields),
			pmin: fields[0]?.pmin ?? 0,
			pmax: fields[fields.length - 1]?.pmax ?? 0,
			origin: 'rulescript',
			line: 0
		};
		#else
		return EBlock(fields);
		#end
	}

	#if hl
	@:noCompletion public inline static function __hl_makeVarArgs(f:Array<Dynamic>->Dynamic, numArgs:Int):Dynamic
	{
		return switch (numArgs)
		{
			case 0:
				() -> f([]);
			case 1:
				Tools.callMethod1.bind(f, _);
			case 2:
				Tools.callMethod2.bind(f, _, _);
			case 3:
				Tools.callMethod3.bind(f, _, _, _);
			case 4:
				Tools.callMethod4.bind(f, _, _, _, _);
			case 5, 6:
				Tools.callMethod6.bind(f, _, _, _, _, _, _);
			case 7, 8:
				Tools.callMethod8.bind(f, _, _, _, _, _, _, _, _);
			case 9, 10, 11, 12:
				Tools.callMethod12.bind(f, _, _, _, _, _, _, _, _, _, _, _, _);
			default:
				Reflect.makeVarArgs(f);
		}
	}

	@:noCompletion public inline static function __hl_callMethod(func:haxe.Constraints.Function, args:Array<Dynamic>):Dynamic
	{
		final ft = hl.Type.getDynamic(func);
		if (ft.kind != HFun)
			throw "Invalid function " + func;

		final need = ft.getArgsCount();

		if (need > 8)
			return rulescript.macro.CallMethodMacro.__hl_callMethod();

		final args:hl.types.ArrayDyn = cast args;

		final count = args.length;
		var nargs = count < need ? need : count;
		var cval:Dynamic = hl.Api.getClosureValue(func);
		if (cval != null)
		{
			func = hl.Api.noClosure(func);
			nargs++;
		}

		var a = new hl.NativeArray<Dynamic>(nargs);
		if (cval == null)
		{
			for (i in 0...count)
				a[i] = args.getDyn(i);
		}
		else
		{
			a[0] = cval;
			for (i in 0...count)
				a[i + 1] = args.getDyn(i);
		}
		return hl.Api.callMethod(func, a);
	}

	@:noCompletion public static function __hl_createInstance<T>(cl:Class<T>, args:Array<Dynamic>):T
	{
		final c:hl.BaseType.Class = cast cl;

		final t = c.__type__;
		if (t == hl.Type.get((null : hl.types.ArrayBase.ArrayAccess)))
			return cast new Array<Dynamic>();

		final o = t.allocObject();
		if (c.__constructor__ != null)
		{
			final v:Dynamic = hl.Api.noClosure(c.__constructor__);
			final args = args.copy();
			args.unshift(o);
			__hl_callMethod(v, args);
		}

		return o;
	}
	#end
}
