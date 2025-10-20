package rulescript;

import rulescript.macro.TypeListMacro;
#if !macro
import haxe.Constraints.Function;
import hscript.Expr;
import hscript.Printer;
import rulescript.types.Abstracts;
import rulescript.types.Property;
import rulescript.types.ScriptedTypeUtil;
import rulescript.types.ScriptedTypedef;
import rulescript.types.Typedefs;
#end

#if hl
@:build(rulescript.macro.CallMethodMacro.build())
#end
class Tools
{
	public static function parseTypePath(typePath:String):TypePath
	{
		return new TypePath(typePath);
	}

	inline public static function startsWithLowerCase(s:String):Bool
		return s.charAt(0) == s.charAt(0).toLowerCase();

	inline public static function startsWithUpperCase(s:String):Bool
		return s.charAt(0) == s.charAt(0).toUpperCase();

	#if !macro
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
	public static function toExpr(e:ExprDef, ?parentExpr:Expr):Expr
	{
		var _e:Expr = parentExpr ?? switch (e)
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
	inline public static function toExpr(e:Expr, ?parentExpr:Expr):Expr
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
		return t is Class && untyped !cast(t, Class<Dynamic>).__IsEnum();
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

	inline public static function isEmptyClass(cl:Class<Dynamic>):Bool
	{
		#if interp
		// Because interp returns an empty class instead of null
		return (cl is Class) ? Type.getClassFields(cl).length == 0 : false;
		#else
		return false;
		#end
	}

	public static function moduleDeclsToExpr(moduleDecls:Array<ModuleDecl>,
			?parameters:{?isScriptedClass:Bool, ?fieldFilter:FieldDecl->Bool, ?classImpl:ClassDecl}):Expr
	{
		final fields:Array<Expr> = [];

		final pushExpr = (e) -> fields.push(toExpr(e));

		final values:Array<Expr> = [];

		function pushField(field:FieldDecl, ?hasExtend:Bool = false)
		{
			if ((parameters?.fieldFilter != null) ? parameters.fieldFilter(field) : true)
			{
				switch (field.kind)
				{
					case KFunction(f):
						if (parameters?.isScriptedClass && (field.access.contains(AOverride) || (field.name == 'new' && hasExtend)))
							pushExpr(EVar('__super_${field.name}', null, toExpr(EIdent(field.name)), false));

						pushExpr(EFunction(f.args, f.expr, field.name, f.ret));
					case KVar(v):
						if (v.get == null && v.set == null)
						{
							pushExpr(EVar(field.name, v.type, null, field.access.contains(APublic), field.access.contains(AFinal)));
						}
						else
						{
							pushExpr(EProp(field.name, v.get, v.set, v.type, null, field.access.contains(APublic)));
						}

						if (v.expr != null)
							values.push(toExpr(EBinop('=', toExpr(EIdent(field.name)), v.expr)));
				}
			}
		}

		inline function pushClassDecl(c:ClassDecl)
		{
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
				pushField(field, c.extend != null);
		}

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
					pushClassDecl(c);
				case DTypedef(c):
				case DField(f):
					pushField(f);
				default:
			}

		if (parameters?.classImpl != null)
		{
			pushClassDecl(parameters.classImpl);
		}

		for (value in values)
			fields.push(value);

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

	public static function resolveType(path:String, ?context:Context):Dynamic
	{
		final lastContext = ScriptedTypeUtil._currentContext;
		ScriptedTypeUtil._currentContext = context;

		var t:Dynamic = ScriptedTypeUtil.resolveScript(path);

		ScriptedTypeUtil._currentContext = lastContext;

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

		t ??= Typedefs.resolveTypedef(path);

		if (shortPath != null)
			t ??= Typedefs.resolveTypedef(shortPath);

		t ??= Type.resolveClass(path);

		#if interp t = Tools.isEmptyClass(t) ? null : t; #end

		if (t == null && shortPath != null)
		{
			t = Type.resolveClass(shortPath);

			#if interp t = Tools.isEmptyClass(t) ? null : t; #end
		}

		t ??= Abstracts.resolveAbstract(path);

		if (shortPath != null)
			t ??= Abstracts.resolveAbstract(shortPath);

		t ??= Type.resolveEnum(path);

		if (shortPath != null)
			t ??= Type.resolveEnum(shortPath);

		return t;
	}

	inline public static function getScriptProp(v:Dynamic):Dynamic
	{
		return v is Property ? cast(v, Property).value : v;
	}

	inline public static function getTypesInPackage(packageName:String):Array<String>
	{
		final list = TypeListMacro.getTypeList()[packageName];

		if (list == null)
			return [];

		return list.copy();
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
	#end
}

@:forward
abstract TypePath(_TypePath)
{
	public var typeName(get, never):String;

	public function new(typePath:String)
	{
		final path:Array<String> = typePath.split('.');

		final pack:Array<String> = [];

		while (path.length > 0 && Tools.startsWithLowerCase(path[0]))
			pack.push(path.shift());

		var typeName:String = null;

		if (path.length > 1)
			typeName = path[1];

		var name = path.length > 0 ? path[0] : pack.pop();

		this = {
			pack: pack,
			name: name,
			sub: typeName,
			fullPath: typePath
		}
	}

	/**
	 * Returns the module path for a type, **excluding the type name**.
	 * Example: For `a.B`, returns `a.B`; for `a.B.C`, returns `a.B`.
	 * 
	 * @return The module path as a String.
	 */
	inline public function modulePath():String
	{
		return if (this.pack.length > 0)
			this.pack.join('.') + '.' + this.name;
		else
			this.name;
	}

	inline function get_typeName():String
	{
		return this.sub ?? this.name;
	}

	public static function create(pack:Array<String>, name:String, sub:String):TypePath
	{
		return new TypePath(createString(pack, name, sub));
	}

	public static function createString(pack:Array<String>, name:String, ?sub:String):String
	{
		var path:String = '';

		if (pack.length > 0)
		{
			path = pack.join('.');

			if (path != '')
				path += '.';
		}

		path += name;

		if (sub != null && name != sub)
			path += '.' + sub;

		return path;
	}

	inline public static function getTypeName(typePath:String):String
	{
		return StringTools.contains(typePath, '.') ? typePath.substring(typePath.lastIndexOf('.') + 1) : typePath;
	}
}

private typedef _TypePath =
{
	var pack:Array<String>;
	var name:String;
	var ?sub:String;
	var fullPath:String;
}
