package rulescript.interps.neo;

import hscript.Expr;
import rulescript.RuleScript.IInterp;
import rulescript.Tools.toExpr;
import rulescript.interps.neo.NeoTypes;
import rulescript.macro.NeoMacro.*;

using rulescript.Tools;

@:access(rulescript.interps.NeoInterp) class NeoCompiler
{
	var interp:NeoInterp;

	public function new(interp:NeoInterp)
	{
		this.interp = interp;
		reset();
	}

	var lastValues:Array<{name:String, value:{id:Int, type:NeoByte}}>;
	var locals:Map<String, {id:Int, type:NeoByte}>;

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

	function setLocal(n:String, obj:{id:Int, type:NeoByte})
	{
		lastValues.push({name: n, value: locals[n]});
		locals[n] = obj;
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
							addInt(locals[id].id);
						}
						else
						{
							addCmd(IDENT);
							addString(id);
						}
				}

			case EVar(n, t, e, global, isFinal):
				addCmd(VAR);

				var id = linkDynamic(null);
				addLink(id);
				setLocal(n, {id: id, type: DYNAMIC});

				if (e == null)
					addCmd(NULL)
				else
					compile(e);

			case EBlock(exprs):
				addCmd(BLOCK);

				addInt(exprs.length);

				scope({
					for (e in exprs)
						compile(e);
				});

			case EBinop(op, e1, e2):
				addCmd(OP);
				switch (op)
				{
					case '=':
						switch (e1.getExpr())
						{
							case EIdent(v):
								if (locals.exists(v))
								{
									addCmd(OP_SET_LOCAL);
									addLink(locals[v].id);
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

					case '+', '-', '*', '/', '%', '<<', '>>', '>>>', '&', '|', '^':
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
							default: error(EInvalidOperator(op));
						});

						compile(e1);
						compile(e2);
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

				skippable(compile(e1));

				if (e2 != null)
					skippable(compile(e2));

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
			// case EDoWhile(cond, e):
			// case EFor(v, it, e):
			// case EForGen(it, e):
			// case EFunction(args, e, name, ret):
			// case EImport(name, star, alias, func):
			// case EMeta(name, args, e):
			// case EProp(n, g, s, t, e, global):
			// case ESwitch(e, cases, defaultExpr):
			// case ETry(e, v, t, ecatch):
			// case ETypeVarPath(path):
			// case EUsing(name):
			// case EWhile(cond, e):

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

	override function get_context():Dynamic
	{
		return interp.context;
	}

	override function set_context(v:Dynamic):Dynamic
	{
		return interp.context = v;
	}

	override function get_isSuperCall():Bool
	{
		return interp.isSuperCall;
	}
}
