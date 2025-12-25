package rulescript.parsers;

import hscript.Expr;
import hscript.Parser.Token;
import rulescript.types.decl.EnumDecl.EnumField;

using StringTools;
using rulescript.Tools;

typedef HxParserParams =
{
	var ?allowJSON:Bool;
	var ?allowMetadata:Bool;
	var ?allowTypes:Bool;
	var ?allowPackage:Bool;
	var ?allowImport:Bool;
	var ?allowUsing:Bool;
	var ?allowStringInterpolation:Bool;
	var ?allowTypePath:Bool;
	var ?allowStaticVariables:Bool;
	var ?allowPublicVariables:Bool;
}

enum HxParserMode
{
	DEFAULT;
	MODULE;
}

class HxParser extends Parser
{
	public var parser:HScriptParser;

	public var mode(get, set):HxParserMode;

	public static var defaultPreprocesorValues:Map<String, Dynamic> = [
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
		parser ??= new HScriptParser();
		mode = DEFAULT;

		for (key => value in defaultPreprocesorValues)
			preprocesorValues.set(key, value);

		super();
	}

	inline public function allowAll():Void
	{
		setParameters({
			allowJSON: true,
			allowMetadata: true,
			allowTypes: true,
			allowPackage: true,
			allowImport: true,
			allowUsing: true,
			allowStringInterpolation: true,
			allowPublicVariables: true,
			allowStaticVariables: true,
			allowTypePath: true
		});
	}

	@:deprecated
	public function setParams(?allowJSON:Bool, ?allowMetadata:Bool, ?allowTypes:Bool, ?allowStringInterpolation:Bool, ?allowTypePath:Bool)
	{
		parser.allowJSON = allowJSON;
		parser.allowMetadata = allowMetadata;
		parser.allowTypes = allowTypes;
		parser.allowStringInterpolation = allowStringInterpolation;
		parser.allowTypePath = allowTypePath;
	}

	public function setParameters(parameters:HxParserParams)
	{
		if (parameters.allowJSON != null)
			parser.allowJSON = parameters.allowJSON;

		if (parameters.allowMetadata != null)
			parser.allowMetadata = parameters.allowMetadata;

		if (parameters.allowTypes != null)
			parser.allowTypes = parameters.allowTypes;

		if (parameters.allowPackage != null)
			parser.allowPackage = parameters.allowPackage;

		if (parameters.allowImport != null)
			parser.allowImport = parameters.allowImport;

		if (parameters.allowUsing != null)
			parser.allowUsing = parameters.allowUsing;

		if (parameters.allowStringInterpolation != null)
			parser.allowStringInterpolation = parameters.allowStringInterpolation;

		if (parameters.allowTypePath != null)
			parser.allowTypePath = parameters.allowTypePath;

		if (parameters.allowStaticVariables != null)
			parser.allowStaticVariables = parameters.allowStaticVariables;

		if (parameters.allowPublicVariables != null)
			parser.allowPublicVariables = parameters.allowPublicVariables;
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

	function get_mode():HxParserMode
	{
		return parser.mode;
	}

	function set_mode(value:HxParserMode):HxParserMode
	{
		return parser.mode = value;
	}
}

@:deprecated("rulescript.parsers.HxParser.HScriptParserPlus was moved to rulescript.parsers.HxParser.HScriptParser")
typedef HScriptParserPlus = HScriptParser;

class HScriptParser extends hscript.Parser
{
	public var mode:HxParserMode;

	public var allowPublicVariables:Bool = true;
	public var allowStaticVariables:Bool = true;

	public var allowPackage:Bool = true;
	public var allowImport:Bool = true;
	public var allowUsing:Bool = true;

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

	var isMainBlock:Bool = false;

	override function parseString(s:String, ?origin:String = "hscript", ?position:Int = 0):Expr
	{
		isMainBlock = true;

		var e = super.parseString(s, origin, position);

		isMainBlock = false;

		return e;
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
								var tk = token();
								switch (tk)
								{
									case TId(s) if (s.startsWithUpperCase()):
										ids.push(s);
									case _:
										push(tk);
										push(TDot);
								}

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

			case TOp('~'):
				var char:Int;

				if (this.char != -1)
				{
					char = this.char;
					this.char = -1;
				}
				else
					char = readChar();

				if (char == '/'.code)
					return parseRegex();

				this.char = char;
				return makeUnop('~', parseExpr());

			case TBrOpen:
				tk = token();
				switch (tk)
				{
					case TBrClose:
						return parseExprNext(mk(EObject([]), p1));
					case TId(_):
						var tk2 = token();
						push(tk2);
						push(tk);
						switch (tk2)
						{
							case TDoubleDot:
								return parseExprNext(parseObject(p1));
							default:
						}
					case TConst(c):
						if (allowJSON)
						{
							switch (c)
							{
								case CString(_):
									var tk2 = token();
									push(tk2);
									push(tk);
									switch (tk2)
									{
										case TDoubleDot:
											return parseExprNext(parseObject(p1));
										default:
									}
								default:
									push(tk);
							}
						}
						else
							push(tk);
					default:
						push(tk);
				}
				var a = new Array();
				while (true)
				{
					final lastIsMainBlock = isMainBlock;

					isMainBlock = false;

					parseFullExpr(a);

					isMainBlock = lastIsMainBlock;

					tk = token();
					if (tk == TBrClose || (resumeErrors && tk == TEof))
						break;
					push(tk);
				}
				return mk(EBlock(a), p1);
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
			case 'package' if (mode == DEFAULT && allowPackage):
				if (!isMainBlock)
					error(ECustom('Package is allowed only in the main block'), p1, tokenMax);

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
			case 'import' if (mode == DEFAULT && allowImport):
				if (!isMainBlock)
					error(ECustom('Import is allowed only in the main block'), p1, tokenMax);

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

				if (!star && path[path.length - 1].startsWithLowerCase())
					func = path.pop();

				var alias:String = null;

				if (maybe(TId('as')))
					!star ? alias = getIdent() : unexpected(TId("as"));
				else if (maybe(TId('in')))
					!star ? alias = getIdent() : unexpected(TId("in"));

				mk(EImport(path.join('.'), star, alias, func), p1, tokenMax);
			case 'using' if (mode == DEFAULT && allowUsing):
				if (!isMainBlock)
					error(ECustom('Using is allowed only in the main block'), p1, tokenMax);

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

				return mk(EUsing(path.join('.')), p1, tokenMax);
			case 'var', 'final':
				var ident = getIdent();

				var props:{get:String, set:String} = null;

				if (id == 'var' && maybe(TPOpen))
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

				final expr = if (props == null)
					EVar(ident, t, e, false, id == 'final')
				else
					EProp(ident, props.get, props.set, t, e);

				mk(expr, p1, (e == null) ? tokenMax : pmax(e));

			case "function":
				var name:String = null;
				final tk = token();
				switch tk
				{
					case TId(id): name = id;
					default: push(tk);
				}
				final inf = parseFunctionDecl();

				mk(EFunction(inf.args, inf.body, name, inf.ret), p1, pmax(inf.body));
			case 'untyped':
				mk(EUntyped(parseExpr()));
			case 'cast':
				var e:Expr, t:CType = null;

				if (maybe(TPOpen))
				{
					e = parseExpr();
					if (allowTypes && maybe(TComma))
						t = parseType();
					ensure(TPClose);
				}
				else
				{
					e = parseExpr();
				}

				mk(ECast(e, t), p1, tokenMax);
			case 'new':
				var hasTypeParams:Bool = false;

				var a = new Array();
				a.push(getIdent());
				while (true)
				{
					var tk = token();
					switch (tk)
					{
						case TDot:
							a.push(getIdent());
						case TPOpen:
							break;
						case TOp('<') if (allowTypes):
							hasTypeParams = true;
							break;
						default:
							unexpected(tk);
							break;
					}
				}

				var typeParams:Array<CType> = null;

				if (hasTypeParams)
				{
					if (maybe(TOp('>')))
						unexpected(TOp('>'));

					typeParams = [];

					while (true)
					{
						typeParams.push(parseType());

						switch (token())
						{
							case TComma:
							case TOp('>'): break;
							case tk: unexpected(tk);
						}
					}

					ensure(TPOpen);
				}

				var args = parseExprList(TPClose);
				mk(ENew(a.join("."), args, typeParams), p1);

			case 'public' if (mode == DEFAULT && allowPublicVariables):
				parseContext(id, false);
			case 'static' if (mode == DEFAULT && allowStaticVariables):
				parseContext(id, true);
			default:
				super.parseStructure(id);
		}
	}

	function parseContext(id:String, isStatic:Bool) // public if not static
	{
		final e:Expr = parseExpr();
		switch (e.getExpr())
		{
			case EVar(n, _), EProp(n, _), EFunction(_, _, n) if (n != null):
				return mk(EMeta(':contextValue', [Tools.toExpr(EIdent(isStatic ? 'static' : 'public'))], e), tokenMin, tokenMax);
			default:
				return unexpected(TId(id));
		}
	}

	function parseStringInterpolation():Expr
	{
		var parts:Array<Expr> = [];
		var backslash = false, dollar = false;
		var old = line;
		var currentString:String = '';

		#if hscriptPos
		var p1 = currentPos - 1;
		#end

		inline function pushString()
		{
			if (currentString != '')
			{
				parts.push(mk(EConst(CString(currentString)), p1, tokenMax));
				currentString = '';
			}
		}

		while (true)
		{
			var c:Int = -1;

			if (this.char < 0)
				c = readChar();
			else
			{
				c = this.char;
				this.char = -1;
			}

			if (StringTools.isEof(c))
			{
				line = old;
				error(EUnterminatedString, p1, p1);
				break;
			}
			if (backslash)
			{
				backslash = false;
				switch (c)
				{
					case 'n'.code:
						currentString += '\n';
					case 'r'.code:
						currentString += '\r';
					case 't'.code:
						currentString += '\t';
					case "'".code, '"'.code, '\\'.code:
						currentString += String.fromCharCode(c);
					case '/'.code:
						if (allowJSON)
							currentString += String.fromCharCode(c);
						else
							invalidChar(c);
					case "u".code:
						if (!allowJSON)
							invalidChar(c);
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
						currentString += String.fromCharCode(k);
					default:
						invalidChar(c);
				}
			}
			else if (dollar)
			{
				dollar = false;

				switch (c)
				{
					case '{'.code:
						pushString();

						parts.push(parseExpr());
						ensure(TBrClose);
					case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
						currentString += '$' + String.fromCharCode(c);
					case "'".code:
						currentString += '$';
						break;
					default:
						if (idents[c])
						{
							pushString();

							currentString = '';

							var id:String = String.fromCharCode(c);

							var char:Int = 0;
							while (true)
							{
								char = readChar();
								if (StringTools.isEof(char))
									char = 0;
								if (!idents[char])
								{
									this.char = char;
									break;
								}
								id += String.fromCharCode(char);
							}

							parts.push(EIdent(id).toExpr());
						}
						else
							currentString += String.fromCharCode(c);
				}
			}
			else if (c == '\\'.code)
				backslash = true;
			else if (c == '$'.code)
				dollar = true;
			else if (c == "'".code)
				break;
			else
			{
				if (c == '\n'.code)
					line++;
				currentString += String.fromCharCode(c);
			}
		}

		pushString();

		final lastPart:Expr = parts[parts.length - 1];

		if (lastPart == null || !lastPart.getExpr().match(EConst(CString(_))))
			parts.push(mk(EConst(CString('')), tokenMax, tokenMax));

		var e = parts.pop();
		while (parts.length > 0)
		{
			e = mk(EBinop('+', parts.pop(), e), tokenMin, tokenMax);
		}

		return e;
	}

	function parseRegex():Expr
	{
		var r:String = '', opt:String = '';

		var backslash:Bool = false;
		while (true)
		{
			var char = readChar();

			switch (char)
			{
				case _ if (StringTools.isEof(char)):
					error(ECustom('Unterminated regular expression'), tokenMin, tokenMax);
				case '\\'.code:
					r += '\\';
					backslash = true;
				case '/'.code if (!backslash):
					break;
				default:
					r += String.fromCharCode(char);
					backslash = false;
			}
		}

		var char = readChar();

		switch (char)
		{
			case 'i'.code, 'g'.code, 'm'.code, 's'.code, 'u'.code:
				opt = String.fromCharCode(char);
			default:
				this.char = char;
		}
		return mk(ENew('EReg', [mk(EConst(CString(r))), mk(EConst(CString(opt)))]));
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
		var isPrivate = false, isExtern = false, isEnum = false;
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

		if (ident == 'enum' && maybe(TId('abstract')))
		{
			ident = 'abstract';
			isEnum = true;
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
							if (extend != null)
								unexpected(t);
							else
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
					isExtern: isExtern
				});
			case "typedef":
				var name = getIdent();
				var params = parseParams();
				ensureToken(TOp("="));
				var t = parseType();
				maybe(TSemicolon);

				return DTypedef({
					name: name,
					meta: meta,
					params: params,
					isPrivate: isPrivate,
					t: t
				});
			case "abstract":
				var name = getIdent();
				var params = parseParams();

				var t = null;

				if (maybe(TPOpen))
				{
					t = parseType();
					ensure(TPClose);
				}

				var from = [], to = [];
				while (true)
				{
					var t = token();

					switch (t)
					{
						case TId('from'):
							from.push(parseType());
						case TId('to'):
							to.push(parseType());
						case TBrOpen:
							break;
						default:
							unexpected(t);
					}
				}

				var fields = [];
				while (!maybe(TBrClose))
					fields.push(parseField());

				return DAbstract({
					meta: meta,
					name: name,
					params: params,
					type: t,
					isExtern: isExtern,
					isPrivate: isPrivate,
					isEnum: isEnum,
					to: to,
					from: from,
					fields: fields
				});
			case 'enum':
				var name = getIdent();
				var params = parseParameters();

				var constructs:Map<String, EnumField> = [];
				var names:Array<String> = [];

				ensure(TBrOpen);

				var id:Int = 0;
				while (!maybe(TBrClose))
				{
					var meta = parseMetadata();
					var name:String = getIdent();
					var params:Array<CType> = parseParameters();
					var type:FieldKind = null;

					if (maybe(TPOpen))
						type = KFunction({args: parseFunctionArgs(), expr: null, ret: null});

					ensure(TSemicolon);

					var field:EnumField = {
						name: name,
						type: type,
						meta: meta,
						index: id++,
						params: params
					}

					constructs[name] = field;
					names.push(name);
				}

				return DEnum({
					meta: meta,
					name: name,
					params: params,
					isPrivate: isPrivate,
					isExtern: isExtern,
					constructs: constructs,
					names: names
				});
			case 'var', 'final', 'function':
				push(TId(ident));
				return DField(parseField());
			default:
				unexpected(TId(ident));
		}
		return null;
	}

	override function parseField():FieldDecl
	{
		var meta = parseMetadata();
		var access = [];
		while (true)
		{
			var id = getIdent();
			switch (id)
			{
				case "override":
					access.push(AOverride);
				case "public":
					access.push(APublic);
				case "private":
					access.push(APrivate);
				case "inline":
					access.push(AInline);
				case "static":
					access.push(AStatic);
				case "macro":
					access.push(AMacro);
				case "function":
					var name = getIdent();
					var inf = parseFunctionDecl();
					return {
						name: name,
						meta: meta,
						access: access,
						kind: KFunction({
							args: inf.args,
							expr: inf.body,
							ret: inf.ret,
						}),
					};
				case "var", "final":
					var name = getIdent();

					if (id == "final")
						access.push(AFinal);

					if (name == 'function')
					{
						push(TId('function'));
					}
					else
					{
						var get = null, set = null;
						if (id == "var" && maybe(TPOpen))
						{
							get = getIdent();
							ensure(TComma);
							set = getIdent();
							ensure(TPClose);
						}
						var type = maybe(TDoubleDot) ? parseType() : null;
						var expr = maybe(TOp("=")) ? parseExpr() : null;

						if (expr != null)
						{
							if (isBlock(expr))
								maybe(TSemicolon);
							else
								ensure(TSemicolon);
						}
						else if (type != null && type.match(CTAnon(_)))
						{
							maybe(TSemicolon);
						}
						else
							ensure(TSemicolon);

						return {
							name: name,
							meta: meta,
							access: access,
							kind: KVar({
								get: get,
								set: set,
								type: type,
								expr: expr,
							}),
						};
					}
				default:
					unexpected(TId(id));
					break;
			}
		}
		return null;
	}

	override function parseParams():{}
	{
		return parseParameters();
	}

	function parseParameters():Array<CType>
	{
		final params:Array<CType> = [];

		if (maybe(TOp('<')))
		{
			while (true)
			{
				params.push(parseType());
				switch (token())
				{
					case TComma:
					case TOp('>'):
						break;
					case tk:
						unexpected(tk);
				}
			}
		}

		return params;
	}

	@:deprecated('rulescript.parsers.HxParser.HScriptParserPlus.moduleDeclsToExpr was moved to rulescript.Tools.moduleDeclsToExpr')
	public function moduleDeclsToExpr(moduleDecls:Array<ModuleDecl>):Expr
	{
		return Tools.moduleDeclsToExpr(moduleDecls);
	}

	/**
	 * Token
	**/
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
									case TOp("-"), TOp("+"):
										switch (token())
										{
											case TConst(CInt(e)): pow = tk.match(TOp("-")) ? -e : e;
											case tk: push(tk);
										}
									default:
										push(tk);
								}
								if (pow == null)
									invalidChar(char);
								if (exp == 0)
									exp = 10;
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
			case TQuestionDouble: "??";
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
