package rulescript;

import hscript.Expr;
import hscript.Parser.Token;

using StringTools;

class HxParser extends Parser
{
	public var parser:HScriptParserPlus;

	public function new()
	{
		parser ??= new HScriptParserPlus();
		super();
	}

	override public function parse(code:String):Expr
	{
		return parser.parseString(code, 'rulescript:HxParser', 0);
	}
}

class HScriptParserPlus extends hscript.Parser
{
	#if hscriptPos
	override function _token():Token
	#else
	override function token():Token
	#end

	{
		var interpolationableString:Bool = input.fastCodeAt(readPos) == "'".code;

		return switch (#if hscriptPos super._token() #else super.token() #end)
		{
			case TConst(CString(s)):
				(s.contains('$') && interpolationableString) ? parseStringInterpolation(s) : TConst(CString(s));
			case t:
				t;
		};
	}
	override function parseStructure(id:String)
	{
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
			default:
				super.parseStructure(id);
		}
	}

	function parseStringInterpolation(s:String):Token
	{
		var parts:Array<Token> = [];

		var isId:Bool = false, insideBraces:Bool = false;

		var currentPart:String = '';

		function addPart()
		{
			if (currentPart != '')
			{
				if (insideBraces)
				{
					var parsedParts = parseLocalStringInterpolation(currentPart);
					if (parsedParts.length > 0)
						parsedParts.push(TOp('+'));

					for (tk in parsedParts)
						parts.push(tk);
				}
				else
				{
					parts.push(isId ? TId(currentPart) : TConst(CString(currentPart)));
					parts.push(TOp('+'));
				}
				currentPart = '';
			}
		}

		for (pos => char in s)
			switch (char)
			{
				case(idents[char] && isId) => true:
					currentPart += String.fromCharCode(char);

				case('$'.code == char && s.charCodeAt(pos + 1) == '$'.code) => true:
					if (isId)
						currentPart += String.fromCharCode(char);

					isId = !isId;

				case('$'.code == char && idents[s.charCodeAt(pos + 1)]) => true:
					addPart();
					isId = true;
				case('$'.code == char && s.charCodeAt(pos + 1) == '{'.code) => true: // Because the $ after '${}' is saved

				case('{'.code == char && s.charCodeAt(pos - 1) == '$'.code) => true:
					addPart();
					isId = insideBraces = true;
				case '}'.code:
					if (isId)
						addPart();
					insideBraces = false;
				default:
					if (isId && !insideBraces)
						addPart();

					if (!insideBraces)
						isId = false;
					currentPart += String.fromCharCode(char);
			}

		addPart();

		// Remove last unusable operator
		parts.pop();

		parts.reverse();

		for (part in parts)
			push(part);

		var tk = token();

		return tk;
	}

	function parseLocalStringInterpolation(s:String):Array<Token>
	{
		var currentPart:String = '';

		var parts:Array<Token> = [];

		var isId:Bool = false, isCall:Bool = false, insideString:Bool = false;

		function addPart()
		{
			if (currentPart != '')
			{
				if (isId)
				{
					parts.push((TId(currentPart.trim())));
					if (isCall)
					{
						isCall = false;
						parts.push(TPOpen);
						parts.push(TPClose);
					}
				}
				else
				{
					parts.push(TConst(CString(currentPart)));
				}
				currentPart = '';
			}
		}

		for (pos => char in s)
		{
			switch (char)
			{
				case(("'".code == char || '"'.code == char) && s.charCodeAt(pos - 1) != '\\'.code) => true:
					isId = false;

					insideString = !insideString;

				// More priority
				case(insideString) => true:
					currentPart += String.fromCharCode(char);

				case(idents[char]) => true:
					currentPart += String.fromCharCode(char);

				case '.'.code:
					isId = true;
					addPart();
					parts.push(TDot);
					isId = true;
				case '+'.code:
					addPart();

					parts.push(TOp('+'));
				case '('.code:
					isCall = true;
				case ')'.code:
				default:
			}
		}
		addPart();

		return parts;
	}
}
