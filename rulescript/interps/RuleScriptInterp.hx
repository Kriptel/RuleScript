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

	// compatibility with old scripts
	// i recommend you to turn on this cuz it's peak for making haxe-accurate scripts
	public var strictMode:Bool = false;

	public var imports:Map<String, Dynamic> = [];
	public var usings:Map<String, Dynamic> = [];
	public var finalVariables:Map<String, Bool> = [];
	public var declaredVariableTypes:Map<String, String> = [];

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
		finalVariables.clear();
		declaredVariableTypes.clear();

		if (rulescript.scriptedClass.RuleScriptedClassUtil.autoWrappers != null)
		{
			for (nativeName => wrapperClass in rulescript.scriptedClass.RuleScriptedClassUtil.autoWrappers)
			{
				variables.set(nativeName, wrapperClass);
			}
		}
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
		
		var me = this;
		
		function resolveOp(op:String, v1:Dynamic, v2:Dynamic):Dynamic {
			if (v1 is rulescript.types.ScriptedAbstract.ScriptedAbstractInstance) {
				var inst = cast(v1, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance);
				if (inst.impl.hasOperator(op)) return inst.impl.callOperator(op, inst, v2, false);
			}
			if (v2 is rulescript.types.ScriptedAbstract.ScriptedAbstractInstance) {
				var inst = cast(v2, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance);
				if (inst.impl.hasOperator(op)) return inst.impl.callOperator(op, inst, v1, true); 
			}
			return null;
		}
		
		binops.set("+", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); 
			var v2:Dynamic = me.expr(e2);
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) + (v2 : Float);
			
			var res:Dynamic = resolveOp("+", v1, v2);
			if (res != null) return res;
			if (Std.isOfType(v1, String) || Std.isOfType(v2, String)) return Std.string(v1) + Std.string(v2);
			return v1 + v2;
		});
		
		binops.set("-", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) - (v2 : Float);
			
			var res:Dynamic = resolveOp("-", v1, v2); 
			if (res != null) return res; 
			return v1 - v2; 
		});
		
		binops.set("*", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) * (v2 : Float);
			
			var res:Dynamic = resolveOp("*", v1, v2); 
			if (res != null) return res; 
			return v1 * v2; 
		});
		
		binops.set("/", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) / (v2 : Float);
			
			var res:Dynamic = resolveOp("/", v1, v2); 
			if (res != null) return res; 
			return v1 / v2; 
		});
		
		binops.set("%", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) % (v2 : Float);
			
			var res:Dynamic = resolveOp("%", v1, v2); 
			if (res != null) return res; 
			return v1 % v2; 
		});
		
		binops.set("==", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return v1 == v2;
			
			var res:Dynamic = resolveOp("==", v1, v2); 
			if (res != null) return res; 
			return v1 == v2; 
		});
		
		binops.set("!=", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return v1 != v2;
			
			var res:Dynamic = resolveOp("!=", v1, v2); 
			if (res != null) return res; 
			return v1 != v2; 
		});
		
		binops.set(">", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) > (v2 : Float);
			
			var res:Dynamic = resolveOp(">", v1, v2); 
			if (res != null) return res; 
			return v1 > v2; 
		});
		
		binops.set("<", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) < (v2 : Float);
			
			var res:Dynamic = resolveOp("<", v1, v2); 
			if (res != null) return res; 
			return v1 < v2; 
		});
		
		binops.set(">=", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) >= (v2 : Float);
			
			var res:Dynamic = resolveOp(">=", v1, v2); 
			if (res != null) return res; 
			return v1 >= v2; 
		});
		
		binops.set("<=", function(e1, e2):Dynamic { 
			var v1:Dynamic = me.expr(e1); var v2:Dynamic = me.expr(e2); 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) <= (v2 : Float);
			
			var res:Dynamic = resolveOp("<=", v1, v2); 
			if (res != null) return res; 
			return v1 <= v2; 
		});
		
		assignOp("+=", function(v1:Dynamic, v2:Dynamic):Dynamic { 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) + (v2 : Float);
			
			var res:Dynamic = resolveOp("+", v1, v2); 
			if (res != null) return res; 
			if (Std.isOfType(v1, String) || Std.isOfType(v2, String)) return Std.string(v1) + Std.string(v2);
			return v1 + v2; 
		});
		
		assignOp("-=", function(v1:Dynamic, v2:Dynamic):Dynamic { 
			if ((v1 is Float || v1 is Int) && (v2 is Float || v2 is Int)) return (v1 : Float) - (v2 : Float);
			
			var res:Dynamic = resolveOp("-", v1, v2); 
			if (res != null) return res; 
			return v1 - v2; 
		});

		binops.set("??", function(e1, e2):Dynamic { 
    		var v1:Dynamic = me.expr(e1); 
			if (v1 != null) return v1; 
			return me.expr(e2); 
		});

		assignOp("??=", function(v1:Dynamic, v2:Dynamic):Dynamic { 
			return v1 != null ? v1 : v2; 
		});
	}

	override function resolve(id:String):Dynamic
	{
		if (id == 'this') 
		{
			if (superInstance != null) return superInstance;
			return this; 
		}

		if (id == 'super' && superInstance != null)
			return superInstance;

		final l:Dynamic = locals.get(id);
		if (l != null)
			return getScriptProp(l.r);

		var v:Dynamic = getScriptProp(variables.get(id));

		if (v == null && !variables.exists(id))
		{
			if (context != null)
			{
				if (context.staticVariables.exists(id))
					v = context.staticVariables.get(id);
				if (context.publicVariables.exists(id))
					v = context.publicVariables.get(id);
			}

			if (v == null && superInstance != null)
				v = get(superInstance, id);

			if (v == null && scriptName != null) {
				final cl = rulescript.scriptedClass.RuleScriptedClassUtil.getClass(scriptName);
				if (cl != null && cl.variableExists(id))
					v = cl.getVariable(id);
			}
			
			if (v == null)
				error(EUnknownVariable(id));
		}

		return v;
	}

	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);

		#if hscriptPos
		curExpr = e1;
		#end

		switch (hscript.Tools.expr(e1))
		{
			case EIdent(id):
				if (id == "this" && superInstance != null && Std.isOfType(superInstance, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance)) {
					cast(superInstance, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance).value = v;
					return v;
				}

				var l:Dynamic = locals.get(id);

				if (strictMode) {
					if (l == null && !variables.exists(id) && !finalVariables.exists(id) &&
						(context == null || (!context.staticVariables.exists(id) && !context.publicVariables.exists(id))) &&
						(superInstance == null || (!superFields.contains(id) && !superFields.contains('set_' + id)))) 
					{
						throw new haxe.Exception('Strict Mode Error: Undeclared variable "$id". Did you forget to write "var $id"?');
					}

					if (declaredVariableTypes.exists(id)) {
						var expected = declaredVariableTypes.get(id);
						if (!checkRuntimeType(v, expected)) {
							var got = Type.getClassName(Type.getClass(v)) ?? Std.string(Type.typeof(v));
							throw new haxe.Exception('Type Mismatch Error: Variable "$id" expects type $expected, but got $got');
						}
					}
				}

				if (l == null)
					setVar(id, v);
				else
				{
					if (l.isFinal) {
						if (l.isInitialized) throw new haxe.Exception('Cannot reassign final variable: ' + id);
						l.isInitialized = true;
					}
					
					if (l.r is Property)
						cast(l.r, Property).value = v;
					else {
						l.r = v;

						if (context != null)
						{
							if (context.staticVariables.exists(id))
								context.staticVariables.set(id, v);

							if (context.publicVariables.exists(id))
								context.publicVariables.set(id, v);
						}
					}
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

				if (Std.isOfType(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance))
					arr = cast(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance).value;

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

		#if hscriptPos
		curExpr = e1;
		#end

		switch (hscript.Tools.expr(e1))
		{
			case EIdent(id):
				var l:Dynamic = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null)
					setVar(id, v);
				else
				{
					if (l.isFinal) {
						if (l.isInitialized) throw new haxe.Exception('Cannot reassign final variable: ' + id);
						l.isInitialized = true;
					}
					
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

				if (Std.isOfType(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance))
					arr = cast(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance).value;

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
				var l:Dynamic = locals.get(id);
				if (l != null && l.isFinal) throw new haxe.Exception('Cannot increment/decrement final variable: ' + id);

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
				
				if (Std.isOfType(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance))
					arr = cast(arr, rulescript.types.ScriptedAbstract.ScriptedAbstractInstance).value;

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
		if (finalVariables.exists(name)) {
			if (finalVariables.get(name))
				throw new haxe.Exception('Cannot reassign global final variable: ' + name);
			else
				finalVariables.set(name, true);
		}

		if (superInstance != null && (superFields.contains(name) || superFields.contains('set_' + name)))
			Reflect.setProperty(superInstance, name, v);
		else if (context != null && context.staticVariables.exists(name))
			context.staticVariables.set(name, v);
		else if (context != null && context.publicVariables.exists(name))
			context.publicVariables.set(name, v);
		else
		{
			final cl = rulescript.scriptedClass.RuleScriptedClassUtil.getClass(scriptName);
			if (cl != null && cl.variableExists(name)) {
				cl.setVariable(name, v);
				return;
			}

			final lastValue = variables.get(name);

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
					case ':multiCatch':
						final errInfo = locals.get("__err__");
						final err = errInfo?.r ?? null;

						@:privateAccess
						final unwrappedErr = Std.isOfType(err, haxe.Exception) ? cast(err, haxe.Exception).unwrap() : err;
						
						for (catchNode in args) {
							switch (catchNode.getExpr()) {
								case EFunction(fargs, catchExpr, _, _):
									final cname = fargs[0].name;
									final expectedTypeStr = fargs[0].t != null ? rulescript.Tools.typeToString(fargs[0].t) : "Dynamic";
									
									if (checkRuntimeType(unwrappedErr, expectedTypeStr)) {
										declared.push({n: cname, old: locals.get(cname)});
										locals.set(cname, {r: unwrappedErr});
										return this.expr(catchExpr);
									}
								default:
							}
						}
						#if hl hl.Api.rethrow(err); #else throw err; #end

					default:
						(onMeta != null) ? onMeta(n, args, e) : exprMeta(n, args, e);
				}

			case EVar(n, tExpr, e, global, isFinal):
				if (tExpr != null) declaredVariableTypes.set(n, rulescript.Tools.typeToString(tExpr));

				if (global) {
					if (context == null || (!context.staticVariables.exists(n) && !context.publicVariables.exists(n))) {
						variables.set(n, (e == null) ? null : this.expr(e));
						if (isFinal) finalVariables.set(n, e != null);
					}
				} else {
					declared.push({n: n, old: locals.get(n)});
					var ref:Dynamic = {r: (e == null) ? null : this.expr(e)};
					if (isFinal) {
						ref.isFinal = true;
						ref.isInitialized = e != null;
					}
					locals.set(n, ref);
				}
				return null;

			case EProp(n, g, s, type, e, global):
				if (type != null) declaredVariableTypes.set(n, rulescript.Tools.typeToString(type));

				var prop = createScriptProperty(n, g, s, type);
				if (global) variables.set(n, prop);
				else {
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: prop});
				}
				if (e != null) prop._lazyValue = () -> this.expr(e);
				return null;

			case EIdent(id):
				return resolve(id);

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
					final isRest = Tools.isRest(p.t);
					if (isRest)
					{
						if (params.indexOf(p) == params.length - 1)
						{
							if (p.opt)
								error(ECustom('Rest argument cannot be optional'));
							else
								hasRest = true;
						}
						else
							error(ECustom("Rest should only be used for the last function argument"));
					}

					if (p.opt || p.value != null)
						hasOpt = true;
					else if (!isRest)
						minParams++;
				}

				var f = function(args:Array<Dynamic>)
				{
					if (args == null)
						args = [];

					if (args.length < minParams)
					{
						var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
						if (name != null)
							str += " for function '" + name + "'";
						error(ECustom(str));
					}

					if (hasOpt || hasRest || params.length != args.length)
					{
						final args2:Array<Dynamic> = [];

						var argId = 0;
						var extraParams = args.length - minParams;
						for (id => param in params)
						{
							var isRest = hasRest && id == params.length - 1 && Tools.isRest(param.t);
							var arg:Dynamic = null;

							if (isRest)
							{
								arg = args.slice(argId);
								argId = args.length;
							}
							else if (param.opt || param.value != null)
							{
								if (extraParams > 0 && argId < args.length)
								{
									arg = args[argId++];
									extraParams--;
								}
								else
								{
									arg = null;
								}
							}
							else
							{
								arg = args[argId++];
							}

							if (arg == null && param.value != null)
								arg = me.expr(param.value);

							args2.push(arg);
						}
						args = args2;
					}

					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					
					for (i in 0...params.length)
					{
						var pName = params[i].name;
						if (pName != null) {
							if (pName.indexOf(':') != -1) pName = pName.substring(0, pName.indexOf(':'));
							if (pName.indexOf('=') != -1) pName = pName.substring(0, pName.indexOf('='));
							pName = StringTools.trim(pName);
						}
						
						me.locals.set(pName, {r: args[i]});
					}

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
				#if rulescript_use_hl_fixes
				var f = if (hasRest)
					Reflect.makeVarArgs(f);
				else
					Tools.__hl_makeVarArgs(f, params.length);
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
					final old = declared.length;

					final isGuard = c.expr != null && c.expr.getExpr().match(EMeta(":guard", _, _));
					final guardCond = isGuard ? switch(c.expr.getExpr()) { case EMeta(_, args, _): args[0]; default: null; } : null;
					final actualExpr = isGuard ? switch(c.expr.getExpr()) { case EMeta(_, _, e): e; default: null; } : c.expr;

					for (v in c.values) {
						if (caseMatch(v, e, val))
						{
							if (guardCond == null || this.expr(guardCond) == true) {
								match = true;
								break;
							}
						}
						restore(old);
					}

					if (match)
					{
						val = this.expr(actualExpr);
						restore(old);
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

	#if rulescript_is_git_hscript override #end function resolveType(path:String):Dynamic
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
		if (#if hl v is StringMap || #end v is haxe.Constraints.IMap)
			return new haxe.iterators.MapKeyValueIterator(v);

		return super.makeKeyValueIterator(v);
	}
	#end

	/**
	 * hasField doesn't work for properties
	 * If getProperty object is null, interp tries to get prop from usings
	 */
	override function get(o:Dynamic, f:String):Dynamic
	{
		if (strictMode) 
			validateFieldAccess(o, f);

		if (o == this)
		{
			if (variables.exists(f))
				return getScriptProp(variables.get(f));
			else
				o = superInstance;
		}

		if (o is IRuleScriptCustomAccessor)
			return cast(o, IRuleScriptCustomAccessor).getField(f);

		if (o is RuleScriptedClass)
		{
			var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
			if (cl.variableExists(f))
				return getScriptProp(cl.getVariable(f));
		}

		var prop:Dynamic = super.get(o, f);
		if (prop != null)
			return getScriptProp(prop);

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

		if (o is ScriptedType)
		{
			switch (cast(o, ScriptedType).__rulescript_type)
			{
				case ENUM:
					var en:ScriptedEnum = cast(o, ScriptedEnum);
					return en.getEnumConstructor(f);
				default:
			}
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
		if (strictMode) 
			validateFieldAccess(o, f);

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
		if (f != null && f == superInstance)
			return call(o, resolve('__super_new'), args);

		#if rulescript_use_hl_fixes
		return Tools.__hl_callMethod(f, args);
		#else
		return super.call(o, f, args);
		#end
	}

	override function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		if (o == superInstance) 
		{
			final nativeSuper = Reflect.field(o, '__super_' + f);
			if (nativeSuper != null) return call(o, nativeSuper, args);
			
			final localSuper = locals.get('__super_' + f);
			if (localSuper != null && localSuper.r != null) return call(o, localSuper.r, args);
		}
		
		return call(o, get(o, f), args);
	}

	override function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		if (cl == "Map" || cl == "haxe.ds.Map")
			return new Map<Dynamic, Dynamic>();

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
					var abs = cast(c, rulescript.types.ScriptedAbstract);
					final inst = abs.createInstance(args);
					
					final ctor = inst.getVariable("new");
					if (ctor != null) {
						@:privateAccess {
							final targetInterp:RuleScriptInterp = cast abs.__impl.interp;
							
							final oldSuper = targetInterp.superInstance;
							targetInterp.superInstance = inst;
							
							final oldThis = targetInterp.variables.exists("this") ? targetInterp.variables.get("this") : null;
							targetInterp.variables.set("this", inst);
							
							Reflect.callMethod(inst, ctor, args);
							
							if (oldThis != null) targetInterp.variables.set("this", oldThis);
							else targetInterp.variables.remove("this");
							
							targetInterp.superInstance = oldSuper;
						}
					}
					
					return inst;
				default:
			}

		#if rulescript_use_hl_fixes
		return Reflect.isFunction(c) ? Tools.__hl_callMethod(c, args) : Tools.isClass(c) ? Tools.__hl_createInstance(c, args) : c;
		#else
		return Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : Tools.isClass(c) ? Type.createInstance(c, args) : c;
		#end
	}

	private function checkRuntimeType(value:Dynamic, expectedType:String):Bool {
		if (value == null || expectedType == null || expectedType == "Dynamic" || expectedType == "Any") return true;
		
		if (expectedType.indexOf("<") != -1) {
			var baseType = expectedType.substring(0, expectedType.indexOf("<"));
			var paramType = expectedType.substring(expectedType.indexOf("<") + 1, expectedType.lastIndexOf(">"));
			
			if (baseType == "Array" && Std.isOfType(value, Array)) {
				var arr:Array<Dynamic> = cast value;
				if (arr.length > 0)
					return checkRuntimeType(arr[0], paramType);

				return true;
			}
			
			if ((baseType == "Map" || baseType == "haxe.ds.Map") && Std.isOfType(value, haxe.Constraints.IMap)) {
				var params = paramType.split(",");
				if (params.length == 2) {
					var mapVal:haxe.Constraints.IMap<Dynamic, Dynamic> = cast value;
					var key = mapVal.keys().next();
					if (key != null) {
						var val = mapVal.get(key);
						return checkRuntimeType(key, StringTools.trim(params[0])) && 
						       checkRuntimeType(val, StringTools.trim(params[1]));
					}
				}
				return true;
			}
			
			expectedType = baseType;
		}

		switch(expectedType) {
			case "Int": return Std.isOfType(value, Int);
			case "Float": return Std.isOfType(value, Float) || Std.isOfType(value, Int);
			case "Bool": return Std.isOfType(value, Bool);
			case "String": return Std.isOfType(value, String);
			default:
				var cls = resolveType(expectedType);
				return cls != null ? Std.isOfType(value, cls) : true;
		}
	}

	private function validateFieldAccess(obj:Dynamic, field:String):Void {
		if (obj == null || obj == this) return;
		
		if (obj is RuleScriptedClass || obj is ScriptedType || obj is haxe.Constraints.IMap) return;
		
		final cls = Type.getClass(obj);
		if (cls == null) return;
		
		final className = Type.getClassName(cls);
		if (className == null || ["String", "Array"].contains(className)) return;
		
		function checkField(c:Class<Dynamic>):Bool {
			if (c == null) return false;
			if (Type.getInstanceFields(c).contains(field) || Type.getClassFields(c).contains(field)) return true;
			if (Type.getInstanceFields(c).contains('get_$field') || Type.getInstanceFields(c).contains('set_$field')) return true;
			return checkField(Type.getSuperClass(c));
		}
		
		if (!checkField(cls)) {
			throw new haxe.Exception('Strict Mode Error: Field "$field" does not exist on class $className');
		}
	}

	function caseMatch(ecase:Expr, evalue:Expr, value:Dynamic):Bool
	{
		if (ecase != null) {
			switch (ecase.getExpr()) {
				case EIdent("_"): 
					return true;
				case EIdent(id):
					if (id != "true" && id != "false" && id != "null") {
						final charCode = id.charCodeAt(0);
						if (charCode >= 97 && charCode <= 122) {
							declared.push({n: id, old: locals.get(id)});
							locals.set(id, {r: value});
							return true;
						}
					}
				default:
			}
		}

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

		if (v != null)
		{
			errorHandler = (exception:haxe.Exception) ->
			{
				#if hscriptPos
				var pos = posInfos();
				@:privateAccess
				if (pos != null && pos.lineNumber > 0 && !Std.isOfType(exception.unwrap(), hscript.Expr.Error))
				{
					var msg = exception.message + ' (at ' + pos.fileName + ':' + pos.lineNumber + ')';
					exception = new haxe.Exception(msg, exception.previous != null ? exception.previous : exception);
				}
				#end

				v(exception);
			};
		}
		else
		{
			errorHandler = null;
		}

		return v;
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
				final exprs:Array<Expr> = switch (rulescript.Tools.getExpr(fexpr))
				{
					case EBlock(exprs):
						exprs;
					default:
						null;
				}

				var preExpr:Expr = fexpr;
				var postExpr:Expr = null;
				var superCallArgs:Array<Expr> = null;

				if (exprs != null)
				{
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

					if (superID != exprs.length)
					{
						preExpr = rulescript.Tools.toExpr(EBlock(exprs.slice(0, superID)));
						postExpr = rulescript.Tools.toExpr(EBlock(exprs.slice(superID + 1)));

						superCallArgs = superID == exprs.length ? [] : switch (rulescript.Tools.getExpr(exprs[superID]))
						{
							case ECall(_, params): params;
							default: [];
						};
					}
				}

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
