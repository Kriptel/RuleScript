package rulescript;

import haxe.Constraints.Function;
import hscript.Expr;

class Tools
{
	public static function usingFunction(?o:Dynamic, f:Function, ?a1:Dynamic, ?a2:Dynamic, ?a3:Dynamic, ?a4:Dynamic, ?a5:Dynamic, ?a6:Dynamic, ?a7:Dynamic,
			?a8:Dynamic)
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

	inline public static function isEmptyClass(cl:Class<Dynamic>)
	{
		#if interp
		// Because interp returns an empty class instead of null
		return cl != null ? Type.getClassFields(cl).length == 0 : false;
		#else
		return false;
		#end
	}

	public static function moduleDeclsToExpr(moduleDecls:Array<ModuleDecl>):Expr
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
						switch (field.kind)
						{
							case KFunction(f):
								pushExpr(EFunction(f.args, f.expr, field.name, f.ret));
							case KVar(v):
								if (v.get == null && v.set == null)
								{
									pushExpr(EVar(field.name, v.type, v.expr, field.access.contains(APublic)));
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
			pmin: fields[0].pmin,
			pmax: fields[fields.length - 1].pmax,
			origin: 'rulescript',
			line: 0
		};
		#else
		return EBlock(fields);
		#end
	}
}
