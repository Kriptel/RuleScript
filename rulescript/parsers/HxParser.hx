package rulescript.parsers;

import hscript.Expr;
import hscript.Parser.Token;

using StringTools;
using rulescript.Tools;

enum HxParserMode
{
	DEFAULT;
	MODULE;
}

class HxParser extends Parser
{
	public var parser:HScriptParserPlus;

	public var mode:HxParserMode = DEFAULT;

	public var defaultPreprocesorValues:Map<String, Dynamic> = [
		#if eval 'eval' => 1, #end
		#if interp 'interp' => 1, #end
		#if cpp 'cpp' => 1, #end
		#if hl 'hl' => 1, #end
		#if hlc 'hlc' => 1, #end
		#if cppia 'cppia' => 1, #end
		#if js 'js' => 1, #end
		#if java 'java' => 1, #end
		#if neko 'neko' => 1, #end
		#if lua 'lua' => 1, #end
		#if php 'php' => 1, #end
		#if python 'python' => 1, #end
		#if swf 'swf' => 1, #end
		#if display 'display' => 1, #end
		#if macro 'macro' => 1, #end
		#if sys 'sys' => 1, #end
		#if static 'static' => 1, #end
		#if unsafe 'unsafe' => 1, #end
		#if debug 'debug' => 1, #end
		'haxe3' => 1,
		'haxe4' => 1
	];

	public var preprocesorValues(get, set):Map<String, Dynamic>;

	public function new()
	{
		parser ??= new HScriptParserPlus();
		for (key => value in defaultPreprocesorValues)
			preprocesorValues.set(key, value);

		super();
	}

	inline public function allowAll():Void
		setParams(true, true, true, true, true);

	public function setParams(?allowJSON:Bool, ?allowMetadata:Bool, ?allowTypes:Bool, ?allowStringInterpolation:Bool, ?allowTypePath:Bool)
	{
		parser.allowJSON = allowJSON;
		parser.allowMetadata = allowMetadata;
		parser.allowTypes = allowTypes;
		parser.allowStringInterpolation = allowStringInterpolation;
		parser.allowTypePath = allowTypePath;
	}

	override public function parse(code:String):Expr
	{
		parser.line = 1;
		return mode == DEFAULT ? parser.parseString(code, 'rulescript', 0) : Tools.moduleDeclsToExpr(parser.parseModule(code, 'rulescript', 0));
	}

	public function parseModule(code:String):Array<ModuleDecl>
	{
		parser.line = 1;
		return parser.parseModule(code, 'rulescript', 0);
	}

	function get_preprocesorValues():Map<String, Dynamic>
	{
		return parser.preprocesorValues;
	}

	function set_preprocesorValues(value:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return parser.preprocesorValues = value;
	}
}

class HScriptParserPlus extends hscript.Parser
{
	public var allowStringInterpolation:Bool = true;
	public var allowTypePath:Bool = true;

	#if !hscriptPos
	static inline final p1:Int = 0;
	static inline final tokenMin:Int = 0;
	static inline final tokenMax:Int = 0;
	#end

	public function new()
	{
		super();
		opPriority.set('...', -2);
	}

	#if hscriptPos
	override function token()
	{
		var t = tokens.pop();
		if (t != null)
		{
			tokenMin = t.min;
			tokenMax = t.max;
			return t.t;
		}
		oldTokenMin = tokenMin;
		oldTokenMax = tokenMax;
		tokenMin = (this.char < 0) ? currentPos : currentPos - 1;
		var t:Token = _token();
		tokenMax = (this.char < 0) ? currentPos - 1 : currentPos - 2;
		return t;
	}
	#end

	#if hscriptPos
	override function _token():Token
	#else
	override function token():Token
	#end
	{
		#if !hscriptPos
		if (!tokens.isEmpty())
			return tokens.pop();
		#end
		var char;
		if (this.char < 0)
			char = readChar();
		else
		{
			char = this.char;
			this.char = -1;
		}
		while (true)
		{
			if (StringTools.isEof(char))
			{
				this.char = char;
				return TEof;
			}
			switch (char)
			{
				case 0:
					return TEof;
				case 32, 9, 13: // space, tab, CR
					#if hscriptPos
					tokenMin++;
					#end
				case 10:
					line++; // LF
					#if hscriptPos
					tokenMin++;
					#end
				case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0...9
					var n = (char - 48) * 1.0;
					var exp = 0.;
					while (true)
					{
						char = readChar();
						exp *= 10;
						switch (char)
						{
							case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
								n = n * 10 + (char - 48);
							case "e".code, "E".code:
								var tk = token();
								var pow:Null<Int> = null;
								switch (tk)
								{
									case TConst(CInt(e)): pow = e;
									case TOp("-"):
										tk = token();
										switch (tk)
										{
											case TConst(CInt(e)): pow = -e;
											default: push(tk);
										}
									default:
										push(tk);
								}
								if (pow == null)
									invalidChar(char);
								return TConst(CFloat((Math.pow(10, pow) / exp) * n * 10));
							case ".".code:
								if (exp > 0)
								{
									// in case of '0...'
									if (exp == 10 && readChar() == ".".code)
									{
										push(TOp("..."));
										var i = Std.int(n);
										return TConst((i == n) ? CInt(i) : CFloat(n));
									}
									invalidChar(char);
								}
								exp = 1.;
							case "x".code:
								if (n > 0 || exp > 0)
									invalidChar(char);
								// read hexa
								#if haxe3
								var n = 0;
								while (true)
								{
									char = readChar();
									switch (char)
									{
										case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
											n = (n << 4) + char - 48;
										case 65, 66, 67, 68, 69, 70: // A-F
											n = (n << 4) + (char - 55);
										case 97, 98, 99, 100, 101, 102: // a-f
											n = (n << 4) + (char - 87);
										default:
											this.char = char;
											return TConst(CInt(n));
									}
								}
								#else
								var n = haxe.Int32.ofInt(0);
								while (true)
								{
									char = readChar();
									switch (char)
									{
										case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
											n = haxe.Int32.add(haxe.Int32.shl(n, 4), cast(char - 48));
										case 65, 66, 67, 68, 69, 70: // A-F
											n = haxe.Int32.add(haxe.Int32.shl(n, 4), cast(char - 55));
										case 97, 98, 99, 100, 101, 102: // a-f
											n = haxe.Int32.add(haxe.Int32.shl(n, 4), cast(char - 87));
										default:
											this.char = char;
											// we allow to parse hexadecimal Int32 in Neko, but when the value will be
											// evaluated by Interpreter, a failure will occur if no Int32 operation is
											// performed
											var v = try CInt(haxe.Int32.toInt(n)) catch (e:Dynamic) CInt32(n);
											return TConst(v);
									}
								}
								#end
							default:
								this.char = char;
								var i = Std.int(n);
								return TConst((exp > 0) ? CFloat(n * 10 / exp) : ((i == n) ? CInt(i) : CFloat(n)));
						}
					}
				case ";".code:
					return TSemicolon;
				case "(".code:
					return TPOpen;
				case ")".code:
					return TPClose;
				case ",".code:
					return TComma;
				case ".".code:
					char = readChar();
					switch (char)
					{
						case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
							var n = char - 48;
							var exp = 1;

							while (true)
							{
								char = readChar();
								exp *= 10;
								switch (char)
								{
									case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
										n = n * 10 + (char - 48);
									default:
										this.char = char;
										return TConst(CFloat(n / exp));
								}
							}
						case ".".code:
							char = readChar();
							if (char != ".".code)
								invalidChar(char);
							return TOp("...");
						default:
							this.char = char;
							return TDot;
					}
				case "{".code:
					return TBrOpen;
				case "}".code:
					return TBrClose;
				case "[".code:
					return TBkOpen;
				case "]".code:
					return TBkClose;
				case "'".code if (allowStringInterpolation):
					return TApostr;
				case "'".code, '"'.code:
					return TConst(CString(readString(char)));
				case "?".code:
					char = readChar();
					if (char == ".".code)
						return TQuestionDot;
					else if (char == '?'.code)
					{
						var char = readChar();

						if (char == '='.code)
							return TOp("??=")
						else
						{
							this.char = char;
							return TOp("??");
						}
					}
					this.char = char;
					return TQuestion;
				case ":".code:
					return TDoubleDot;
				case '='.code:
					char = readChar();
					if (char == '='.code)
						return TOp("==");
					else if (char == '>'.code)
						return TOp("=>");
					this.char = char;
					return TOp("=");
				case '@'.code:
					char = readChar();
					if (idents[char] || char == ':'.code)
					{
						var id = String.fromCharCode(char);
						while (true)
						{
							char = readChar();
							if (!idents[char])
							{
								this.char = char;
								return TMeta(id);
							}
							id += String.fromCharCode(char);
						}
					}
					invalidChar(char);
				case '#'.code:
					char = readChar();
					if (idents[char])
					{
						var id = String.fromCharCode(char);
						while (true)
						{
							char = readChar();
							if (!idents[char])
							{
								this.char = char;
								return preprocess(id);
							}
							id += String.fromCharCode(char);
						}
					}
					invalidChar(char);
				default:
					if (ops[char])
					{
						var op = String.fromCharCode(char);
						while (true)
						{
							char = readChar();
							if (StringTools.isEof(char))
								char = 0;
							if (!ops[char])
							{
								this.char = char;
								return TOp(op);
							}
							var pop = op;
							op += String.fromCharCode(char);
							if (!opPriority.exists(op) && opPriority.exists(pop))
							{
								if (op == "//" || op == "/*")
									return tokenComment(op, char);
								this.char = char;
								return TOp(pop);
							}
						}
					}
					if (idents[char])
					{
						var id = String.fromCharCode(char);

						while (true)
						{
							char = readChar();
							if (StringTools.isEof(char))
								char = 0;
							if (!idents[char])
							{
								this.char = char;
								return TId(id);
							}
							id += String.fromCharCode(char);
						}
					}
					invalidChar(char);
			}
			char = readChar();
		}
		return null;
	}

	override function parseExpr()
	{
		var tk = token();
		#if hscriptPos
		var p1 = tokenMin;
		#end
		return switch (tk)
		{
			case TId(id):
				var e = parseStructure(id);

				if (allowTypePath && e == null && id.startsWithLowerCase())
				{
					var tk = token();
					if (tk == TDot)
					{
						var ids = [id];

						while (true)
						{
							var ident = getIdent();
							ids.push(ident);

							var tk = token();
							if (tk != TDot)
							{
								push(tk);
								break;
							}

							if (ident.startsWithUpperCase())
							{
								push(TDot);
								break;
							}
						}

						if (ids[ids.length - 1].startsWithUpperCase())
							e = mk(ETypeVarPath(ids));
						else
						{
							while (ids.length > 1)
							{
								push(TId(ids.pop()));
								push(TDot);
							}
						}
					}
					else
						push(tk);
				}

				if (e == null)
					e = mk(EIdent(id));

				return parseExprNext(e);

			case TPOpen:
				tk = token();
				if (tk == TPClose)
				{
					ensureToken(TOp("->"));
					var eret = parseExpr();
					return mk(EFunction([], mk(EReturn(eret), p1)), p1);
				}
				push(tk);

				var rest = maybe(TOp('...'));

				var e = parseExpr();
				tk = token();
				switch (tk)
				{
					case TPClose:
						return parseExprNext(mk(EParent(e), p1, tokenMax));
					case TDoubleDot:
						var t = rest ? CTPath(["haxe", "Rest"], [parseType()]) : parseType();

						tk = token();
						switch (tk)
						{
							case TPClose:
								return parseExprNext(mk(ECheckType(e, t), p1, tokenMax));
							case TComma:
								switch (expr(e))
								{
									case EIdent(v):
										return parseLambda([{name: v, t: t}], pmin(e));
									default:
								}
							default:
						}
					case TComma:
						switch (expr(e))
						{
							case EIdent(v):
								return parseLambda([{name: v}], pmin(e));
							default:
						}

					default:
				}
				return unexpected(tk);

			case TApostr:
				parseExprNext(parseStringInterpolation());
			default:
				push(tk);
				super.parseExpr();
		}
	}

	override function parseLambda(args:Array<Argument>, pmin):Expr
	{
		while (true)
		{
			var rest:Bool = maybe(TOp('...'));
			var id:String = getIdent();
			var t = maybe(TDoubleDot) ? parseType() : null;
			if (rest)
				t = CTPath(["haxe", "Rest"], [t]);
			args.push({name: id, t: t});
			var tk = token();
			switch (tk)
			{
				case TComma:
				case TPClose:
					break;
				default:
					unexpected(tk);
					break;
			}
		}
		ensureToken(TOp("->"));
		var eret = parseExpr();
		return mk(EFunction(args, mk(EReturn(eret), pmin)), pmin);
	}

	override function parseStructure(id:String)
	{
		#if hscriptPos
		var p1 = tokenMin;
		#end

		return switch (id)
		{
			case 'package':
				var path:Array<String> = [];

				var tk = token();
				switch (tk)
				{
					case TId(s):
						path.push(s);
						while (true)
						{
							var t = token();
							if (t != TDot)
							{
								push(t);
								break;
							}
							t = token();
							switch (t)
							{
								case TId(id):
									path.push(id);
								default:
									unexpected(t);
							}
						}
					default:
						push(tk);
				}

				mk(EPackage(path.join('.')));
			case 'import':
				var path:Array<String> = [getIdent()];
				var star = false;

				while (true)
				{
					var t = token();
					if (t != TDot)
					{
						push(t);
						break;
					}
					t = token();
					switch (t)
					{
						case TId(id):
							path.push(id);
						case TOp("*"):
							star = true;
						default:
							unexpected(t);
					}
				}

				var func:String = null;

				var char = path[path.length - 1].charAt(0);
				if (char == char.toLowerCase())
					func = path.pop();

				var alias:String = null;

				if (maybe(TId('as')))
					!star ? alias = getIdent() : unexpected(TId("as"));
				else if (maybe(TId('in')))
					!star ? alias = getIdent() : unexpected(TId("in"));

				mk(EImport(path.join('.'), star, alias, func));
			case 'using':
				var path = [getIdent()];
				while (true)
				{
					var t = token();
					if (t != TDot)
					{
						push(t);
						break;
					}
					t = token();
					switch (t)
					{
						case TId(id):
							path.push(id);
						default:
							unexpected(t);
					}
				}

				return mk(EUsing(path.join('.')));
			case "var":
				var ident = getIdent();

				var props:{get:String, set:String} = null;
				if (maybe(TPOpen))
				{
					var list:Array<Expr> = parseExprList(TPClose);

					if (list.length != 2)
						list.length > 2 ? unexpected(TComma) : unexpected(TPClose);
					else
					{
						var get:String = switch (expr(list[0]))
						{
							case EIdent(id):
								id;
							case _:
								error(ECustom('Accessor should be ident'), tokenMin, tokenMax);
								null;
						}, set:String = switch (expr(list[1]))
							{
								case EIdent(id):
									id;
								case _:
									error(ECustom('Accessor should be ident'), tokenMin, tokenMax);
									null;
							}

						props = {get: get, set: set}
					}
				}

				var tk = token();
				var t = null;
				if (tk == TDoubleDot && allowTypes)
				{
					t = parseType();
					tk = token();
				}
				var e = null;
				if (Type.enumEq(tk, TOp("=")))
					e = parseExpr();
				else
					push(tk);

				if (props == null)
				{
					mk(EVar(ident, t, e), p1, (e == null) ? tokenMax : pmax(e));
				}
				else
				{
					mk(EProp(ident, props.get, props.set, t, e), p1, (e == null) ? tokenMax : pmax(e));
				}

			case "for":
				ensure(TPOpen);
				var vname:String = getIdent();
				var vval:String = maybe(TOp("=>")) ? getIdent() : null;

				ensureToken(TId("in"));
				var eiter = parseExpr();
				ensure(TPClose);
				var e = parseExpr();
				mk(EFor(vname, eiter, e, vval), p1, pmax(e));
			default:
				super.parseStructure(id);
		}
	}

	function parseStringInterpolation():Expr
	{
		var char:Int = 0;
		var backslash = false, dollar = false;
		var parts:Array<rulescript.RuleScript.StringOrExpr> = [];
		var currentPart:Int = 0;

		var old = line;

		#if hscriptPos
		var p1 = currentPos - 1;
		#end

		while (true)
		{
			if (this.char < 0)
				char = readChar();
			else
			{
				char = this.char;
				this.char = -1;
			}

			if (StringTools.isEof(char))
			{
				line = old;
				error(EUnterminatedString, p1, p1);
				break;
			}

			if (backslash)
			{
				backslash = false;
				switch (char)
				{
					case 'n'.code:
						this.char = '\n'.code;
					case 'r'.code:
						this.char = '\r'.code;
					case 't'.code:
						this.char = '\t'.code;
					case "'".code, '"'.code, '\\'.code:
						this.char = char;
					case '/'.code:
						if (allowJSON)
							this.char = char;
						else
							invalidChar(char);
					case "u".code:
						if (!allowJSON)
							invalidChar(char);
						var k = 0;
						for (i in 0...4)
						{
							k <<= 4;
							var char = readChar();
							switch (char)
							{
								case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
									k += char - 48;
								case 65, 66, 67, 68, 69, 70: // A-F
									k += char - 55;
								case 97, 98, 99, 100, 101, 102: // a-f
									k += char - 87;
								default:
									if (StringTools.isEof(char))
									{
										line = old;
										error(EUnterminatedString, p1, p1);
									}
									invalidChar(char);
							}
						}
						this.char = k;
					default:
						invalidChar(char);
				}
			}
			else if (char == '$'.code && !dollar)
			{
				var c = readChar();
				this.char = c;
				if (c == '$'.code)
				{
					dollar = true;
				}
				else
					switch (token())
					{
						case TBrOpen:
							currentPart = parts.push(parseExpr());
							ensure(TBrClose);
						case TId(s):
							currentPart = parts.push(mk(EIdent(s)));
						case TApostr:
							parts[currentPart] += String.fromCharCode(char);
							this.char = "'".code;
						default:
					}
			}
			else if (char == '\\'.code)
			{
				backslash = true;
			}
			else if (char == "'".code)
			{
				break;
			}
			else
			{
				parts[currentPart] ??= '';

				if (char == '\n'.code)
					line++;

				parts[currentPart] += String.fromCharCode(char);
			}
		}

		var e:Expr = null;

		var currentPart:Int = 0;
		while (parts.length > currentPart)
		{
			var part:Dynamic = parts[currentPart++];
			if (part is String)
				part = mk(EConst(CString(cast part)));
			else
			{
				switch (Tools.getExpr(part))
				{
					case EConst(c):
					default:
						part = mk(EParent(part));
				}
			}

			if (e == null)
				e = part;
			else
				e = makeBinop('+', e, part);
		}
		return e ?? mk(EConst(CString('')));
	}

	override function parseFunctionArgs()
	{
		var args = new Array();
		var tk = token();
		if (tk != TPClose)
		{
			var done = false;
			while (!done)
			{
				var name:String = null, opt:Bool = false, isRest:Bool = false;

				switch (tk)
				{
					case TOp("..."):
						isRest = true;
						tk = token();
					case TQuestion:
						opt = true;
						tk = token();
					default:
				}

				switch (tk)
				{
					case TId(id):
						name = id;
					default:
						unexpected(tk);
						break;
				}
				var arg:Argument = {name: name};
				args.push(arg);
				if (opt)
					arg.opt = true;
				if (allowTypes)
				{
					if (maybe(TDoubleDot))
						arg.t = isRest ? CTPath(["haxe", "Rest"], [parseType()]) : parseType();
					if (maybe(TOp("=")))
						arg.value = parseExpr();
				}
				tk = token();
				switch (tk)
				{
					case TComma:
						tk = token();
					case TPClose:
						done = true;
					default:
						unexpected(tk);
				}
			}
		}
		return args;
	}

	override function parseModuleDecl():ModuleDecl
	{
		var meta = parseMetadata();
		var ident = getIdent();
		var isPrivate = false, isExtern = false;
		while (true)
		{
			switch (ident)
			{
				case "private":
					isPrivate = true;
				case "extern":
					isExtern = true;
				default:
					break;
			}
			ident = getIdent();
		}
		switch (ident)
		{
			case "package":
				var path:Array<String> = [];

				var tk = token();
				switch (tk)
				{
					case TId(s):
						path.push(s);
						while (true)
						{
							var t = token();
							if (t != TDot)
							{
								push(t);
								break;
							}
							t = token();
							switch (t)
							{
								case TId(id):
									path.push(id);
								default:
									unexpected(t);
							}
						}
					default:
						push(tk);
				}

				ensure(TSemicolon);

				return DPackage(path);
			case "import":
				var path:Array<String> = [getIdent()];
				var star = false;

				while (true)
				{
					var t = token();
					if (t != TDot)
					{
						push(t);
						break;
					}
					t = token();
					switch (t)
					{
						case TId(id):
							path.push(id);
						case TOp("*"):
							star = true;
						default:
							unexpected(t);
					}
				}

				var func:String = null;

				var char = path[path.length - 1].charAt(0);
				if (char == char.toLowerCase())
					func = path.pop();

				var alias:String = null;

				if (maybe(TId('as')))
					!star ? alias = getIdent() : unexpected(TId("as"));
				else if (maybe(TId('in')))
					!star ? alias = getIdent() : unexpected(TId("in"));

				ensure(TSemicolon);

				return DImport(path, star, alias, func);
			case 'using':
				var path = [getIdent()];
				while (true)
				{
					var t = token();
					if (t != TDot)
					{
						push(t);
						break;
					}
					t = token();
					switch (t)
					{
						case TId(id):
							path.push(id);
						default:
							unexpected(t);
					}
				}

				ensure(TSemicolon);

				return DUsing(path.join('.'));
			case "class":
				var name = getIdent();
				var params = parseParams();
				var extend = null;
				var implement = [];

				while (true)
				{
					var t = token();
					switch (t)
					{
						case TId("extends"):
							extend = parseType();
						case TId("implements"):
							implement.push(parseType());
						default:
							push(t);
							break;
					}
				}

				var fields = [];
				ensure(TBrOpen);
				while (!maybe(TBrClose))
					fields.push(parseField());

				return DClass({
					name: name,
					meta: meta,
					params: params,
					extend: extend,
					implement: implement,
					fields: fields,
					isPrivate: isPrivate,
					isExtern: isExtern,
				});
			case "typedef":
				var name = getIdent();
				var params = parseParams();
				ensureToken(TOp("="));
				var t = parseType();
				return DTypedef({
					name: name,
					meta: meta,
					params: params,
					isPrivate: isPrivate,
					t: t,
				});
			default:
				unexpected(TId(ident));
		}
		return null;
	}

	@:deprecated('rulescript.parsers.HxParser.HScriptParserPlus.moduleDeclsToExpr was moved to rulescript.Tools.moduleDeclsToExpr')
	public function moduleDeclsToExpr(moduleDecls:Array<ModuleDecl>):Expr
	{
		return Tools.moduleDeclsToExpr(moduleDecls);
	}

	override function tokenString(t)
	{
		return switch (t)
		{
			case TEof: "<eof>";
			case TConst(c): constString(c);
			case TId(s): s;
			case TOp(s): s;
			case TPOpen: "(";
			case TPClose: ")";
			case TBrOpen: "{";
			case TBrClose: "}";
			case TDot: ".";
			case TQuestionDot: "?.";
			case TComma: ",";
			case TSemicolon: ";";
			case TBkOpen: "[";
			case TBkClose: "]";
			case TQuestion: "?";
			case TDoubleDot: ":";
			case TMeta(id): "@" + id;
			case TPrepro(id): "#" + id;
			case TApostr: "<apostrophe>";
		}
	}
}
