package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import rulescript.Tools.TypePath;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class AbstractMacro
{
	macro public static function build():Array<Field>
	{
		final defaultFilename:String = 'RuleScriptAbstracts.txt';
		final filename:String = Context.definedValue('rulescript_abstracts_file_path');

		final abstractsList:Array<String> = [];
		final ignoreList:Array<String> = [];

		for (dir in Context.getClassPath())
		{
			for (name in (filename != null ? [defaultFilename, filename] : [defaultFilename]))
				if (FileSystem.exists(dir + name))
					for (abs in parseFile(File.getContent(dir + name)))
					{
						if (abs.startsWith('#') || abs.startsWith('//') || abs.length == 0) {} // Comment
						else if (abs.startsWith('-#')) // Ignore
							ignoreList.push(abs);
						else if (!abstractsList.contains(abs)) // Add
							abstractsList.push(abs);
					}
		}

		final list = [
			for (abstractType in abstractsList)
			{
				if (!ignoreList.contains('-#$abstractType'))
					buildAbstract(new TypePath(abstractType));
			}
		];

		final fields = Context.getBuildFields();
		fields.push({
			name: 'list',
			access: [APublic, AStatic],
			kind: FVar(macro :Map<String, Dynamic>, macro $a{list}),
			pos: Context.currentPos()
		});
		return fields;
	}

	static function parseFile(content:String):Array<String>
	{
		final lines = content.replace('\r', '').split('\n');
		var active = true;
		var result:Array<String> = [];
		var conditionMet = false;
		var stack:Array<{active:Bool, conditionMet:Bool}> = [];
		
		for (line in lines)
		{
			var trimmed = line.trim();
			
			if (trimmed.startsWith('#if '))
			{
				stack.push({active: active, conditionMet: conditionMet});
				var condition = trimmed.substr(4).trim();
				active = evaluateCondition(condition) && active;
				conditionMet = active;
			}
			else if (trimmed.startsWith('#elseif '))
			{
				if (conditionMet)
				{
					active = false;
				}
				else
				{
					var condition = trimmed.substr(8).trim();
					active = evaluateCondition(condition) && stack[stack.length - 1].active;
					conditionMet = active;
				}
			}
			else if (trimmed == '#else')
			{
				active = stack[stack.length - 1].active && !conditionMet;
				conditionMet = true;
			}
			else if (trimmed == '#end')
			{
				var state = stack.pop();
				if (state != null)
				{
					active = state.active;
					conditionMet = state.conditionMet;
				}
			}
			else if (active && trimmed.length > 0)
			{
				if (trimmed.startsWith('-#'))
					result.push(trimmed);
				else if (!trimmed.startsWith('//'))
					result.push(trimmed.replace(' ', ''));
			}
		}
		
		return result;
	}

	static function evaluateCondition(condition:String):Bool
	{
		var tokens = tokenize(condition);
		var pos = 0;
		
		function peek():{type:String, value:String}
		{
			return tokens[pos];
		}
		
		function consume(type:String, ?value:String):{type:String, value:String}
		{
			var token = peek();
			if (token == null)
				Context.error('Unexpected end of condition: $condition', Context.currentPos());
			if (token.type != type)
				Context.error('Expected token of type $type, but got ${token.type} in condition: $condition', Context.currentPos());
			if (value != null && token.value != value)
				Context.error('Expected token with value $value, but got ${token.value} in condition: $condition', Context.currentPos());
			pos++;
			return token;
		}
		
		var parseExpression:Void->Bool = null;
		var parseOr:Void->Bool = null;
		var parseAnd:Void->Bool = null;
		var parseComparison:Void->Bool = null;
		var parseUnary:Void->Bool = null;
		var parsePrimary:Void->Bool = null;
		
		parsePrimary = function():Bool
		{
			if (peek() == null)
				Context.error('Unexpected end of condition in condition: $condition', Context.currentPos());
			
			if (peek().type == "(")
			{
				consume("(");
				var result = parseExpression();
				if (peek() == null || peek().type != ")")
					Context.error('Expected closing parenthesis in condition: $condition', Context.currentPos());
				consume(")");
				return result;
			}
			else if (peek().type == "id")
			{
				var token = consume("id");
				return Context.defined(token.value);
			}
			else if (peek().type == "num")
			{
				var token = consume("num");
				return Std.parseFloat(token.value) != 0;
			}
			else if (peek().type == "str")
			{
				var token = consume("str");
				return token.value != "";
			}
			else
			{
				Context.error('Unexpected token ${peek().type} in condition: $condition', Context.currentPos());
				return false;
			}
		}
		
		parseUnary = function():Bool
		{
			if (peek() != null && peek().type == "op" && peek().value == "!")
			{
				consume("op", "!");
				return !parseUnary();
			}
			return parsePrimary();
		}
		
		parseComparison = function():Bool
		{
			var left = parseUnary();
			while (peek() != null && peek().type == "cmp")
			{
				var op = consume("cmp").value;
				var right = parseUnary();
				
				switch (op)
				{
					case "==": left = left == right;
					case "!=": left = left != right;
					case "<", ">", "<=", ">=":
						Context.error('Comparison operators <, >, <=, >= are not supported for boolean values', Context.currentPos());
						left = false;
					default:
						Context.error('Unknown comparison operator: $op', Context.currentPos());
				}
			}
			return left;
		}
		
		parseAnd = function():Bool
		{
			var left = parseComparison();
			while (peek() != null && peek().type == "op" && peek().value == "&&")
			{
				consume("op", "&&");
				var right = parseComparison();
				left = left && right;
			}
			return left;
		}
		
		parseOr = function():Bool
		{
			var left = parseAnd();
			while (peek() != null && peek().type == "op" && peek().value == "||")
			{
				consume("op", "||");
				var right = parseAnd();
				left = left || right;
			}
			return left;
		}
		
		parseExpression = function():Bool
		{
			return parseOr();
		}
		
		return parseExpression();
	}

	static function tokenize(condition:String):Array<{type:String, value:String}>
	{
		var tokens:Array<{type:String, value:String}> = [];
		var i = 0;
		var length = condition.length;
		
		while (i < length)
		{
			var c = condition.charAt(i);
			
			if (c == ' ')
			{
				i++;
				continue;
			}
			
			if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_')
			{
				var start = i;
				while (i < length && 
				      ((condition.charAt(i) >= 'a' && condition.charAt(i) <= 'z') ||
					   (condition.charAt(i) >= 'A' && condition.charAt(i) <= 'Z') ||
					   (condition.charAt(i) >= '0' && condition.charAt(i) <= '9') ||
					   condition.charAt(i) == '_'))
				{
					i++;
				}
				var value = condition.substring(start, i);
				tokens.push({type: "id", value: value});
				continue;
			}
			
			if (c >= '0' && c <= '9')
			{
				var start = i;
				var dot = false;
				while (i < length && 
				      (condition.charAt(i) >= '0' && condition.charAt(i) <= '9') ||
					  (!dot && condition.charAt(i) == '.'))
				{
					if (condition.charAt(i) == '.') dot = true;
					i++;
				}
				var value = condition.substring(start, i);
				tokens.push({type: "num", value: value});
				continue;
			}
			
			if (c == '"' || c == "'")
			{
				var quote = c;
				var start = i;
				i++;
				while (i < length && condition.charAt(i) != quote)
				{
					i++;
				}
				if (i >= length)
					Context.error('Unclosed string literal in condition: $condition', Context.currentPos());
				var value = condition.substring(start + 1, i);
				tokens.push({type: "str", value: value});
				i++;
				continue;
			}
			
			if (c == '&' && i + 1 < length && condition.charAt(i + 1) == '&')
			{
				tokens.push({type: "op", value: "&&"});
				i += 2;
				continue;
			}
			
			if (c == '|' && i + 1 < length && condition.charAt(i + 1) == '|')
			{
				tokens.push({type: "op", value: "||"});
				i += 2;
				continue;
			}
			
			if (c == '!')
			{
				if (i + 1 < length && condition.charAt(i + 1) == '=')
				{
					tokens.push({type: "cmp", value: "!="});
					i += 2;
				}
				else
				{
					tokens.push({type: "op", value: "!"});
					i++;
				}
				continue;
			}
			
			if (c == '=')
			{
				if (i + 1 < length && condition.charAt(i + 1) == '=')
				{
					tokens.push({type: "cmp", value: "=="});
					i += 2;
				}
				else
				{
					tokens.push({type: "op", value: "="});
					i++;
				}
				continue;
			}
			
			if (c == '(')
			{
				tokens.push({type: "(", value: "("});
				i++;
				continue;
			}
			
			if (c == ')')
			{
				tokens.push({type: ")", value: ")"});
				i++;
				continue;
			}
			
			Context.error('Unexpected character $c in condition: $condition', Context.currentPos());
		}
		
		return tokens;
	}

	static function buildAbstract(typePath:TypePath):Expr
	{
		var type = switch (Context.getType(typePath.fullPath))
		{
			case TAbstract(t, params):
				t.get();
			default:
				Context.warning('Type ${typePath.fullPath} is not an abstract', Context.currentPos());
				null;
		}

		var alias:String = null;

		if (type.meta.has(':alias'))
		{
			var meta = [
				for (meta in type.meta.get())
					if (meta.name == ':alias')
						meta
			][0];

			alias = ExprTools.getValue(meta.params[0]);

			if (typePath.pack.length > 0 && !ExprTools.getValue(meta.params[1] ?? macro false))
				alias = typePath.pack.join('.') + '.' + alias;
		}

		var value:Expr = {
			expr: EObjectDecl([
				for (field in type.impl.get().statics.get())
					if (!field.meta.has(':ignoreField') && field.name != '_new')
					{
						var isStatic:Bool = true;

						switch (field.expr()?.expr)
						{
							case TFunction(f):
								if (f.args[0] != null && f.args[0].v.name == 'this')
									isStatic = false;
							default:
						}

						if (!field.kind.match(FVar(AccCall, _)) && isStatic)
							{
								field: field.name,
								expr: macro @:privateAccess $p{'${typePath.fullPath}.${field.name}'.split('.')}
							}
					}
			]),
			pos: Context.currentPos()
		}

		return macro $v{alias ?? typePath.fullPath} => $e{value};
	}
}
#end
