package rulescript.parsers;

import hscript.Expr;
import hscript.Parser.Token;

typedef HxParserParams =
{
	var ?allowJSON:Bool;
	var ?allowMetadata:Bool;
	var ?allowTypes:Bool;
	var ?allowStringInterpolation:Bool;
}

enum HxParserMode
{
	DEFAULT;
	MODULE;
}

class HxParser implements IParser
{
	public var parser:HScriptParser;

	public function new(context:Context)
	{
		parser ??= new HScriptParser(context);
	}

	public function parse(input:String):ParseResult
	{
		return Expression(parser.parseString(input, 'rulescript', 0));
	}

	inline public function allowAll():Void
	{
		setParameters({
			allowJSON: true,
			allowMetadata: true,
			allowTypes: true,
			allowStringInterpolation: true
		});
	}

	public function setParameters(parameters:HxParserParams)
	{
		if (parameters.allowJSON != null)
			parser.allowJSON = parameters.allowJSON;

		if (parameters.allowMetadata != null)
			parser.allowMetadata = parameters.allowMetadata;

		if (parameters.allowTypes != null)
			parser.allowTypes = parameters.allowTypes;

		if (parameters.allowStringInterpolation != null)
			parser.allowStringInterpolation = parameters.allowStringInterpolation;
	}
}

class HScriptParser extends hscript.Parser
{
	public var context:Context;

	public var mode:HxParserMode;

	public var allowStringInterpolation:Bool = true;

	public function new(context:Context)
	{
		super();
		this.context = context;
		opPriority.set('...', -2);
	}

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

	override function evalPreproCond(e:Expr)
	{
		final v:Dynamic = evalPreprocessor(e);
		return v != false && v != null;
	}

	function evalPreprocessor(e:Expr):Dynamic
	{
		switch (expr(e))
		{
			case EIdent(id):
				return preprocValue(id);
			case EConst(c):
				return switch (c)
				{
					case CInt(v): Std.string(v);
					case CFloat(v): Std.string(v);
					case CString(s): s;
				}
			case EUnop("!", _, e):
				return !evalPreprocessor(e);
			case EParent(e):
				return evalPreprocessor(e);
			case EBinop(op, e1, e2):
				var v1:Dynamic = evalPreprocessor(e1),
					v2:Dynamic = evalPreprocessor(e2);

				return switch (op)
				{
					case "&&": v1 && v2;
					case "||": v1 || v2;
					case "==": v1 == v2;
					case ">": v1 > v2;
					case ">=": v1 >= v2;
					case "<": v1 < v2;
					case "<=": v1 <= v2;
					default:
						error(EInvalidPreprocessor("Unsupported operation '" + op + "'"), currentPos, currentPos);
						false;
				}
			default:
				error(EInvalidPreprocessor("Can't eval " + expr(e).getName()), currentPos, currentPos);
				return false;
		}
	}

	override function preprocValue(id:String):Dynamic
	{
		if (preprocesorValues.exists(id))
			return preprocesorValues.get(id);

		if (context != null)
			return context.defines.get(id);

		return null;
	}
}
