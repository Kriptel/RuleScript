package rulescript.interps.neo;

import hscript.Expr;
import rulescript.Tools.toExpr;
import rulescript.interps.neo.NeoTypes;
import rulescript.macro.NeoMacro.*;

using StringTools;
using rulescript.Tools;

@:access(rulescript.interps.NeoInterp) class NeoCompiler
{
	var interp:NeoInterp;

	public function new(interp:NeoInterp)
	{
		this.interp = interp;
		reset();
	}

	var lastValues:Array<{name:String, ?value:Int}>;
	var locals:Map<String, Int>;

	public function reset()
	{
		lastValues = [];
		locals = [];
	}

	function restore(num:Int)
	{
		while (lastValues.length > num)
		{
			final v = lastValues.pop();

			if (v.value == null)
				locals.remove(v.name);
			else
				locals[v.name] = v.value;
		}
	}

	function setLocal(n:String, id:Int)
	{
		lastValues.push({name: n, value: locals[n]});
		locals[n] = id;
	}

	public function compileExpr(expr:Expr):Void
	{
		scope(compile(expr));
	}

	#if hscriptPos
	var lastLine:Int = -1;
	#end

	function compile(expr:Expr):Void
	{
		#if hscriptPos
		if (interp.lineInfo && lastLine != expr.line)
		{
			addCmd(LINE);
			addInt(lastLine = expr.line);
		}
		#end

		switch (expr.getExpr())
		{
			case EUntyped(e):
				switch (e.getExpr())
				{
					case EIdent('__rulescript__interpType'):
						addCmd(INTERP_TYPE);
					default:
				}
			case EConst(c):
				switch (c)
				{
					case CInt(v):
						addCmd(INT);
						addInt(v);
					case CFloat(f):
						addCmd(FLOAT);
						addFloat(f);
					case CString(s):
						addCmd(STRING);
						addString(s);
				}

			case EIdent(id):
				switch (id)
				{
					case 'null':
						addCmd(NULL);
					case 'true':
						addCmd(BOOL_TRUE);
					case 'false':
						addCmd(BOOL_FALSE);
					default:
						if (locals.exists(id))
						{
							addCmd(IDENT_LOCAL);
							addInt(locals[id]);
						}
						else
						{
							addCmd(IDENT);
							addString(id);
						}
				}

			case EVar(name, type, expr, global, isFinal):
				if (global)
					compile(EBinop('=', EIdent(name).toExpr(), expr).toExpr());
				else
				{
					addCmd(VAR);

					var local = addHiddenLocal(name);

					if (expr == null)
						addCmd(NULL)
					else
						compile(expr);

					local.show();
				}
			case EProp(name, get, set, type, expr, global):
				var local:Null<{id:Int, show:Void->Void}> = null;

				if (global)
				{
					addCmd(PROPERTY);
					addString(name);
				}
				else
				{
					addCmd(PROPERTY_LOCAL);
					local = addHiddenLocal(name);
				}

				switch (get)
				{
					case 'default':
						addCmd(PROP_DEFAULT);
					case 'get':
						addCmd(PROP_CALLBACK);
						compile(EFunction([], ECall(EIdent('get_$name').toExpr(), []).toExpr()).toExpr());
					case 'null':
						addCmd(PROP_NULL);
					case 'dynamic':
						addCmd(PROP_DYNAMIC);
						compile(EFunction([], ECall(EIdent('get_$name').toExpr(), []).toExpr()).toExpr());
					case 'never':
						addCmd(PROP_NEVER);
					default:
						throw '$name: Custom property accessor is no longer supported, please use `get`';
				}

				switch (set)
				{
					case 'default':
						addCmd(PROP_DEFAULT);
					case 'set':
						addCmd(PROP_CALLBACK);
						compile(EFunction([{name: 'v'}], ECall(EIdent('set_$name').toExpr(), [EIdent('v').toExpr()]).toExpr()).toExpr());
					case 'null':
						addCmd(PROP_NULL);
					case 'dynamic':
						addCmd(PROP_DYNAMIC);
						compile(EFunction([{name: 'v'}], ECall(EIdent('set_$name').toExpr(), [EIdent('v').toExpr()]).toExpr()).toExpr());
					case 'never':
						addCmd(PROP_NEVER);
					default:
						throw '$name: Custom property accessor is no longer supported, please use `set`';
				}

				if (expr != null)
					compile(EFunction([], EBlock([EVar('__v', type, expr).toExpr(), EIdent('__v').toExpr()]).toExpr()).toExpr());
				else
					addCmd(NULL);

				if (local != null)
					local.show();

			case EBlock(exprs):
				addCmd(BLOCK);

				addInt(exprs.length);

				scope({
					for (e in exprs)
						compile(e);
				});

			case EBinop(op, e1, e2):
				switch (op)
				{
					case '=':
						addCmd(OP);

						switch (e1.getExpr())
						{
							case EIdent(v):
								if (locals.exists(v))
								{
									addCmd(OP_SET_LOCAL);
									addLink(locals[v]);
								}
								else
								{
									addCmd(OP_SET);
									addString(v);
								}

							case EField(e, f):
								addCmd(OP_SET_FIELD);

								compile(e);

								addString(f);

							case EArray(e, index):
								addCmd(OP_SET_ARRAY);

								compile(e);

								compile(index);

							default:
								error(EInvalidOperator('='));
						}

						compile(e2);
					case '&&', '||':
						addCmd(OP);

						addCmd(switch (op)
						{
							case '&&': OP_AND;
							case '||': OP_OR;
							default: error(EInvalidOperator(op));
						});

						compile(e1);
						skippable(compile(e2));

					case '+', '-', '*', '/', '%', '<<', '>>', '>>>', '&', '|', '^', '==', '!=', '<', '<=', '>', '>=':
						addCmd(OP);

						addCmd(switch (op)
						{
							case '+': OP_PLUS;
							case '-': OP_MINUS;
							case '*': OP_MULT;
							case '/': OP_DIVISION;
							case '%': OP_MODULO;
							case '<<': OP_SHIFT_LEFT;
							case '>>': OP_SHIFT_RIGHT;
							case '>>>': OP_UNSIGNED_SHIFT_RIGHT;
							case '&': OP_BIT_AND;
							case '|': OP_BIT_OR;
							case '^': OP_BIT_XOR;
							case '==': OP_EQUALS;
							case '!=': OP_NOT_EQUALS;
							case '<': OP_LT;
							case '<=': OP_LT_EQUAL;
							case '>': OP_GT;
							case '>=': OP_GT_EQUAL;
							default: error(EInvalidOperator(op));
						});

						compile(e1);
						compile(e2);
					case '%=', '*=', '/=', '+=', '-=', '<<=', '>>=', '>>>=', '&=', '|=', '^=':
						compile(EBinop('=', e1, EBinop(op.substr(0, -1), e1, e2).toExpr()).toExpr());
					default:
						error(EInvalidOperator(op));
				}

			case EUnop(op, prefix, e):
				switch (op)
				{
					case '!', '~':
						addCmd(OP);
						addCmd(switch (op)
						{
							case '!': OP_NOT;
							case '~': OP_BIT_NEGATION;
							default: error(EInvalidOperator(op));
						});

						compile(e);

					case '++', '--':
						if (prefix)
							compile(toExpr(EBinop('=', e, {
								toExpr(EBinop(op == '++' ? '+' : '-', e, toExpr(EConst(CInt(1)))));
							})));
						else
						{
							compile(toExpr(EBlock([
								// Setting an impossible identifier
								toExpr(EVar('0', null, e)),
								toExpr(EBinop('=', e, {
									toExpr(EBinop(op == '++' ? '+' : '-', e, toExpr(EConst(CInt(1)))));
								})),
								toExpr(EIdent('0')),
							])));
						}
					default:
						error(EUnsupportedExpr(expr));
				}

			case ECall(e, args):
				addCmd(CALL);

				compile(e);

				addInt(args.length);
				for (arg in args)
					compile(arg);

			case EIf(cond, e1, e2), ETernary(cond, e1, e2):
				addCmd(e2 == null ? IF : IF_ELSE);

				compile(cond);

				skippable(scope(compile(e1)));

				if (e2 != null)
					skippable(scope(compile(e2)));

			case EParent(e):
				compile(e);

			case EArray(e, index):
				addCmd(ARRAY);

				compile(e);

				compile(index);

			case EArrayDecl(exprs):
				final isMap:Bool = exprs.length > 0 && exprs[0].getExpr().match(EBinop("=>", _));

				addCmd(isMap ? CREATE_MAP : CREATE_ARRAY);

				// Maps check types using the first element, so it is set manually.
				addInt(isMap ? exprs.length - 1 : exprs.length);

				for (e in exprs)
				{
					if (isMap)
						switch (e.getExpr())
						{
							case EBinop('=>', e1, e2):
								compile(e1);
								compile(e2);
							default:
								error(EInvalidMap('Expected a => b'));
						}
					else
						compile(e);
				}

			case EObject(fl):
				addCmd(CREATE_OBJECT);

				addInt(fl.length);

				for (f in fl)
				{
					addString(f.name);
					compile(f.e);
				}

			case EField(e, f):
				addCmd(FIELD);

				compile(e);

				addString(f);

			case ECast(e), ECheckType(e, _), EReturn(e), EThrow(e):
				addCmd(switch (expr.getExpr())
				{
					case ECast(_): CAST;
					case ECheckType(_): CHECK_TYPE;
					case EReturn(_): RETURN;
					case EThrow(_): THROW;
					default: error(EUnsupportedExpr(expr));
				});
				compile(e);

			case EContinue:
				addCmd(CONTINUE);

			case EBreak:
				addCmd(BREAK);

			case EPackage(path):
				addCmd(PACKAGE);
				addString(path);

			case ENew(cl, params, _):
				addCmd(NEW);

				addString(cl);
				addInt(params.length);
				for (param in params)
					compile(param);
			case EFor(v, it, e):
				addCmd(FOR);

				scope({
					addLocal(v);

					compile(it);
					compile(e);
				});

			#if (hscript >= "2.7.0")
			case EForGen(it, e):
				var key:String = null, value:String = null;
				var iterator:Expr = null;

				switch (it.getExpr())
				{
					case EBinop('in', e1, e2):
						switch (e1.getExpr())
						{
							case EBinop('=>', k, v):
								key = switch (k.getExpr())
								{
									case EIdent(id): id;
									default: error(EUnsupportedExpr(k));
								}

								value = switch (v.getExpr())
								{
									case EIdent(id): id;
									default: error(EUnsupportedExpr(v));
								}
							default:
								error(EUnsupportedExpr(e1));
						}
						iterator = e2;
					default:
						error(EUnsupportedExpr(it));
				}

				addCmd(FOR_KEY_VALUE);

				scope({
					addLocal(key);
					addLocal(value);
					compile(iterator);

					compile(e);
				});
			#end

			case EWhile(cond, e):
				addCmd(WHILE);

				compile(cond);

				skippable(scope({
					compile(e);
				}));

			case EDoWhile(cond, e):
				addCmd(DO_WHILE);

				scope(compile(e));

				compile(cond);

			case ETry(e, v, _, ecatch):
				addCmd(TRY);

				skippable(scope(compile(e)));

				skippable(scope({
					addLocal(v);
					compile(ecatch);
				}));

			case EImport(name, star, alias, func):
				addCmd(RS_IMPORT);
				addString(name);
				addBool(star);
				addString(alias);
				addString(func);

			case EFunction(args, e, name, ret):
				switch (name)
				{
					// case 'new':
					// addCmd(CONSTRUCTOR);
					case null:
						addCmd(ANON_FUNCTION);
					default:
						addCmd(FUNCTION);
						addString(name);
				};

				addInt(args.length);

				var minArgs:Int = 0;
				for (arg in args)
				{
					if (!arg.opt)
						minArgs++;
				}

				addInt(minArgs);

				final isRest:Bool = (args.length > 0 && args[args.length - 1].t.match(CTPath(["haxe", "Rest"], _)));

				addBool(isRest);

				skippable(scope({
					for (arg in args)
						addLocal(arg.name);

					skippable(compile(e));
				}));
			case EMeta(name, args, e):
				addCmd(META);
				addString(name);

				if (args == null)
					addInt(-1);
				else
				{
					addInt(args.length);
					for (arg in args)
						addDynamic(arg); // The expression remains in AST form
				}

				compile(e);
			case EUsing(name):
				addCmd(USING);
				addString(name);

			case ESwitch(e, cases, defaultExpr):
				addCmd(SWITCH);
				compile(e);

				addInt(cases.length);

				skippable(for (c in cases)
				{
					addInt(c.values.length);
					skippable(for (v in c.values) compile(v));

					skippable(scope(compile(c.expr)));
				});

				skippable(defaultExpr == null ? addCmd(NULL) : scope(compile(defaultExpr)));
			case ETypeVarPath(path):
				addCmd(TYPE_VAR_PATH);

				addDynamic(path);
			default:
				error(EUnsupportedExpr(expr));
		}
	}

	inline function error(e:NeoError):Dynamic
	{
		return interp.error(e);
	}

	inline function currentPos():Int
	{
		return interp.bytes.length;
	}

	inline function addCmd(cmd:NeoByte):Int
	{
		return interp.bytes.push(cmd);
	}

	inline function addInt(i:Int):Int
	{
		return interp.bytes.push(i);
	}

	inline function addBool(b:Bool):Int
	{
		return interp.bytes.push(b ? BOOL_TRUE : BOOL_FALSE);
	}

	inline function setInt(pos:Int, v:Int):Int
	{
		return interp.bytes[pos - 1] = v;
	}

	inline function addLink(i:Int):Int
	{
		return interp.bytes.push(i);
	}

	inline function addFloat(fl:Float):Int
	{
		return interp.bytes.push(linkFloat(fl));
	}

	inline function addString(str:String):Int
	{
		return interp.bytes.push(linkString(str));
	}

	inline function addDynamic(dyn:Dynamic):Int
	{
		return interp.bytes.push(linkDynamic(dyn));
	}

	inline function addLocal(name:String):Int
	{
		var id = linkDynamic(null);
		addLink(id);
		setLocal(name, id);

		return id;
	}

	inline function addHiddenLocal(name:String):{id:Int, show:Void->Void}
	{
		var id = linkDynamic(null);
		addLink(id);

		return {id: id, show: () -> setLocal(name, id)};
	}

	inline function linkFloat(fl:Float):Int
	{
		return interp.floatBuffer.push(fl) - 1;
	}

	inline function linkString(str:String):Int
	{
		return interp.stringBuffer.push(str) - 1;
	}

	inline function linkDynamic(dyn:Dynamic):Int
	{
		return interp.dynamicBuffer.push(dyn) - 1;
	}
}

@:access(rulescript.interps.NeoInterp)
class NeoInterpAccess extends RuleScriptAccess
{
	var interp:NeoInterp;

	public function new(interp:NeoInterp)
	{
		this.interp = interp;
	}

	override function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	inline extern overload override function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return interp.variables = newVariables;
	}

	override function resetVariables():Void
	{
		interp.reset();
	}

	override function resetInterp():Void
	{
		interp.reset();
	}

	override function variableExists(name:String):Bool
	{
		return interp.variables.exists(name);
	}

	override function getVariable(name:String):Dynamic
	{
		return interp.variables[name];
	}

	override function setVariable(name:String, value:Dynamic):Dynamic
	{
		return interp.variables[name] = value;
	}

	override function removeVariable(name:String):Bool
	{
		return interp.variables.remove(name);
	}

	override function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		return if (variableExists(name))
		{
			#if hl
			Tools.__hl_callMethod(getVariable(name), args);
			#else
			Reflect.callMethod(null, getVariable(name), args);
			#end
		}
		else
			null;
	}

	override function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		return #if hl
			Tools.__hl_callMethod(getVariable(name), args);
		#else
			Reflect.callMethod(null, getVariable(name), args);
		#end
	}

	override function execute(expr:Expr):Dynamic
	{
		return interp.execute(expr);
	}

	override function get_scriptName():String
	{
		return interp.scriptName;
	}

	override function set_scriptName(v:String):String
	{
		return interp.scriptName = v;
	}

	override function get_scriptPackage():String
	{
		return interp.scriptPackage;
	}

	override function set_scriptPackage(v:String):String
	{
		return interp.scriptPackage = v;
	}

	override function get_superInstance():Dynamic
	{
		return interp.superInstance;
	}

	override function set_superInstance(v:Dynamic):Dynamic
	{
		return interp.superInstance = v;
	}

	override function get_hasErrorHandler():Bool
	{
		return interp.hasErrorHandler;
	}

	override function set_hasErrorHandler(v:Bool):Bool
	{
		return interp.hasErrorHandler = v;
	}

	override function get_errorHandler():haxe.Exception->Void
	{
		return interp.errorHandler;
	}

	override function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
	{
		return interp.errorHandler = v;
	}

	override function get_context():Context
	{
		return interp.context;
	}

	override function set_context(v:Context):Context
	{
		return interp.context = v;
	}

	override function get_isSuperCall():Bool
	{
		return interp.isSuperCall;
	}
}
