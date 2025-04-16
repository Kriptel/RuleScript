package rulescript;

import haxe.Constraints.IMap;
import hscript.Expr;
import rulescript.RuleScript.IInterp;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;

using StringTools;
using rulescript.Tools;

@:build(rulescript.macro.CommandMacro.build())
enum abstract Command(Int) from Int
{
	// BASIC COMMANDS
	var CONST = 0;
	var LINK = 1;
	var NATIVE_FIELD = 2;
	var RETURN = 3;
	var CONTINUE = 4;
	var BREAK = 5;
	var SUPER = 6;
	var CONSTRUCTOR = 7;

	var GET = 10;
	var GET_NATIVE = 11;
	var GET_SCRIPTED_TYPE = 12;
	var SET = 13;
	var SET_NATIVE = 14;
	var OP = 15;
	var OP_FLOAT = 16;
	var OP_NATIVE = 17;
	var CALL = 18;
	var CALL_USING = 19;
	var BLOCK = 20;
	var STRING_CONCAT = 21;
	var FOR = 22;
	var FOR_KEY_VALUE = 23;
	var WHILE = 24;
	var DO_WHILE = 25;
	var IF = 26;
	var IF_ELSE = 27;
	var NEW = 28;
	var IDENT_NATIVE = 29;

	// TYPES
	var INT = 40;
	var FLOAT = 41;
	var STRING = 42;
	var BOOL = 43;
	var ARRAY = 44;
	var MAP = 45;
	var CLASS = 46;
	var ENUM = 47;
	var ENUM_VALUE = 48;
	var VOID = 49;
	var FUNCTION = 50;
	var LOCAL_FUNCTION = 51;
	var ANON_FUNCTION = 52;
	var NULL = 53;
	var DYNAMIC = 54;
	var OBJECT = 55;

	// MAP
	var MAP_STRING = 56;
	var MAP_INT = 57;
	var MAP_ENUM_VALUE = 58;
	var MAP_OBJECT = 59;

	// VARIABLE
	var VARIABLE_INT = 60;
	var VARIABLE_FLOAT = 61;
	var VARIABLE_STRING = 62;
	var VARIABLE_BOOL = 63;
	var VARIABLE_DYNAMIC = 64;

	// OTHER FEATURES
	var CAST_INT_TO_FLOAT = 70;
	var CREATE_OBJECT = 71;
	var BOOL_TRUE = 72;
	var BOOL_FALSE = 73;
	var BUFFER_LINK = 74;
	var ARRAY_GET = 75;
	var ARRAY_SET = 76;
	var MAP_GET = 77;
	var MAP_SET = 78;
	var OBJECT_SET = 79;
	var OBJECT_SET_PROP = 80;
	var INT_ITERATOR = 81;

	// OPERATORS
	var OP_PLUS = 100;
	var OP_MINUS = 101;
	var OP_MULT = 102;
	var OP_DIVISION = 103;

	var OP_MODULO = 104;

	var OP_SHIFT_LEFT = 105;
	var OP_SHIFT_RIGHT = 106;
	var OP_UNSIGNED_SHIFT_RIGHT = 107;
	var OP_BIT_AND = 108;
	var OP_BIT_OR = 109;
	var OP_BIT_XOR = 110;

	var OP_BIT_NEGATION = 111;

	var OP_ARITHMETIC_NEGATION = 112;
	var OP_ARITHMETIC_NEGATION_FLOAT = 113;

	var OP_POST_INCREMENT = 114;
	var OP_POST_DECREMENT = 115;

	var OP_POST_INCREMENT_FLOAT = 116;
	var OP_POST_DECREMENT_FLOAT = 117;

	var OP_DYNAMIC = 130;

	var EQUAL = 131;
	var NOT_EQUAL = 132;
	var NOT = 133;
	var AND = 134;
	var OR = 135;

	var OP_LT = 136;
	var OP_LT_EQUAL = 137;
	var OP_GT = 138;
	var OP_GT_EQUAL = 139;

	// COMMANDS
	var PACKAGE = 200;
	var IMPORT = 201;
	var USING = 202;

	@:to inline public function toString():String
		return COMMAND_LIST[this] ?? '$this';

	@:to inline public function toInt():Int
		return this;

	inline public function isMap():Bool
		return this == MAP_STRING || this == MAP_INT || this == MAP_ENUM_VALUE || this == MAP_OBJECT;
}

/**
 * TODO:
 * - Properties
 * - Switch
 * - Rest
 * - Try
 */
class BytecodeInterp implements IInterp
{
	public var scriptName:String;
	public var scriptPackage(default, set):String;

	public var access:RuleScriptAccess;

	public var variables:Map<String, Dynamic> = [];

	public var superInstance(default, set):Dynamic;

	public var hasErrorHandler:Bool;
	public var errorHandler(default, set):haxe.Exception->Void;

	public var isSuperCall:Bool = false;

	/**
	 * used by the interpreter when type is dynamic
	 */
	public var binops:Map<String, (Dynamic, Dynamic) -> Dynamic> = [];

	var converter:Converter;

	public function new()
	{
		access = new InterpAccess(this);

		initOps();
		reset();
		scriptPackage = '';
		converter = new Converter(this);
	}

	private function initOps()
	{
		binops["+"] = (a:Dynamic, b:Dynamic) -> a + b;
		binops["-"] = (a:Dynamic, b:Dynamic) -> a - b;
		binops["*"] = (a:Dynamic, b:Dynamic) -> a * b;
		binops["/"] = (a:Dynamic, b:Dynamic) -> a / b;
		binops["%"] = (a:Dynamic, b:Dynamic) -> a % b;
		binops["^"] = (a:Int, b:Int) -> a ^ b;
		binops["&"] = (a:Int, b:Int) -> a & b;
		binops["|"] = (a:Int, b:Int) -> a | b;
		binops["&&"] = (a:Bool, b:Bool) -> a == true && b == true;
		binops["||"] = (a:Bool, b:Bool) -> a == true || b == true;
		binops["??"] = (a:Dynamic, b:Dynamic) -> a ?? b;
		binops["<<"] = (a:Int, b:Int) -> a << b;
		binops[">>"] = (a:Int, b:Int) -> a >> b;
		binops[">>>"] = (a:Int, b:Int) -> a >>> b;
		binops["=="] = (a:Dynamic, b:Dynamic) -> a == b;
		binops["!="] = (a:Dynamic, b:Dynamic) -> a != b;
		binops[">="] = (a:Dynamic, b:Dynamic) -> a >= b;
		binops["<="] = (a:Dynamic, b:Dynamic) -> a <= b;
		binops[">"] = (a:Dynamic, b:Dynamic) -> a > b;
		binops["<"] = (a:Dynamic, b:Dynamic) -> a < b;
		binops["..."] = (a:Int, b:Int) -> a...b;
		binops["is"] = (a:Dynamic, b:Dynamic) -> Std.isOfType(a, b);
	}

	var floatBuffer:Array<Float>;
	var stringBuffer:Array<String>;
	var nativeClassBuffer:Array<Class<Dynamic>>;
	var dynamicBuffer:Array<Dynamic>;

	var __usings:Map<String, Dynamic> = [];

	var _buffer:Array<Command>;
	var pos:Int;

	inline function next()
		return _buffer[pos++];

	var linkType:Command = -1;

	var linkID:Int = -1;

	inline function getValue():Dynamic
	{
		return switch (linkType)
		{
			case INT:
				linkID;
			case FLOAT:
				floatBuffer[linkID];
			case STRING:
				stringBuffer[linkID];
			case DYNAMIC, FUNCTION, OBJECT:
				dynamicBuffer[linkID];
			case CLASS:
				nativeClassBuffer[linkID];
			case BOOL:
				linkID == BOOL_TRUE;
			case NULL, VOID:
				null;
			case BUFFER_LINK:
				_buffer[linkID];
			case SUPER:
				superInstance;
			default:
				throw linkType.toString();
		}
	}

	public function execute(e:Expr):Dynamic
	{
		converter.convertExpr(e);

		command();

		return getValue();
	}

	public function reset()
	{
		floatBuffer = [];
		stringBuffer = [];
		dynamicBuffer = [];
		nativeClassBuffer = [];

		__usings.clear();

		variables.clear();
		variables.set('trace', Reflect.makeVarArgs(function(args:Array<Dynamic>)
		{
			haxe.Log.trace(args.join(', '), cast {
				fileName: scriptName,
				lineNumber: 0
			});

			return;
		}));

		_buffer = [];
		pos = 0;
	}

	function command():Command
	{
		switch (next())
		{
			case CONST:
				switch (next())
				{
					case INT:
						linkID = next();
						return linkType = INT;
					case FLOAT:
						linkID = next();
						return linkType = FLOAT;
					case STRING:
						linkID = next();
						return linkType = STRING;
					case CLASS:
						linkID = next();
						return linkType = CLASS;
					case command:
						throw command.toString();
				}
			case SUPER:
				return linkType = SUPER;

			case NATIVE_FIELD:
				final field:String = stringBuffer[next().toInt()];
				final id:Int = next();

				dynamicBuffer[id] = Reflect.getProperty(superInstance, field);
				linkID = id;

				return linkType = DYNAMIC;

			case BOOL_TRUE:
				linkID = BOOL_TRUE;
				return linkType = BOOL;

			case BOOL_FALSE:
				linkID = BOOL_FALSE;
				return linkType = BOOL;

			case BLOCK:
				var i:Int = next().toInt();

				while (i-- != 0)
				{
					switch (command())
					{
						case RETURN:
							return RETURN;
						case BREAK:
							return BREAK;
						case CONTINUE:
							return CONTINUE;
						default:
					}
				}
				return linkType;

			case SET:
				final type = next();
				final id:Int = next();
				command();
				final valueId:Int = linkID;

				switch (type)
				{
					case STRING:
						stringBuffer[id] = stringBuffer[valueId];
					case INT:
						_buffer[id] = valueId;
					case BOOL:
						_buffer[id] = valueId;
					case FLOAT:
						floatBuffer[id] = floatBuffer[valueId];
					case DYNAMIC:
						dynamicBuffer[id] = dynamicBuffer[valueId];
					default:
						throw type;
				}

				return linkType = type;

			case SET_NATIVE:
				final id:Int = next();
				final name = stringBuffer[next().toInt()];
				command();

				dynamicBuffer[id] = variables[name] = getValue();

				linkID = id;

				return linkType = DYNAMIC;

			case OBJECT_SET:
				final field:String = stringBuffer[next().toInt()];
				command();
				final obj:Dynamic = getValue();
				command();
				final value:Dynamic = getValue();

				Reflect.setField(obj, field, value);

				return linkType;

			case OBJECT_SET_PROP:
				final field:String = stringBuffer[next().toInt()];
				command();
				final obj:Dynamic = getValue();
				command();
				final value:Dynamic = getValue();

				Reflect.setProperty(obj, field, value);

				return linkType;

			case OP_POST_INCREMENT:
				final type = next();
				final id:Int = next();

				final lastValue:Int = _buffer[id];

				_buffer[id] = _buffer[id].toInt() + 1;

				linkID = lastValue;
				return linkType = INT;

			case OP_POST_DECREMENT:
				final type = next();
				final id:Int = next();

				final lastValue:Int = _buffer[id];

				_buffer[id] = _buffer[id].toInt() - 1;

				linkID = lastValue;
				return linkType = INT;

			case OP_POST_INCREMENT_FLOAT:
				final id:Int = next();

				final type = next();
				final valueId:Int = next();

				final lastValue:Float = floatBuffer[valueId];
				switch (linkType)
				{
					case FLOAT:
						floatBuffer[valueId] = floatBuffer[valueId] + 1;
					default:
						throw linkType;
				}

				floatBuffer[id] = lastValue;

				linkID = id;
				return linkType = FLOAT;

			case OP_POST_DECREMENT_FLOAT:
				final id:Int = next();

				final type = next();
				final valueId:Int = next();

				final lastValue:Float = floatBuffer[valueId];
				switch (linkType)
				{
					case FLOAT:
						floatBuffer[valueId] = floatBuffer[valueId] - 1;
					default:
						throw linkType;
				}

				floatBuffer[id] = lastValue;

				linkID = id;
				return linkType = FLOAT;

			case EQUAL:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a == b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case NOT_EQUAL:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a != b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case AND:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a && b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case OR:
				inline function getCommandValue():Bool
				{
					command();
					return cast getValue();
				}

				linkID = if (getCommandValue() || getCommandValue())
					BOOL_TRUE
				else
					BOOL_FALSE;

				return linkType = BOOL;

			case OP_GT:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a > b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case OP_LT:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a < b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case OP_GT_EQUAL:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a >= b) ? BOOL_TRUE : BOOL_FALSE;
				return linkType = BOOL;

			case OP_LT_EQUAL:
				command();
				final a:Dynamic = getValue();
				command();
				final b:Dynamic = getValue();

				linkID = (a <= b) ? BOOL_TRUE : BOOL_FALSE;

				return linkType = BOOL;

			case IF:
				final endPos:Int = next();
				command();
				if (linkID == BOOL_TRUE)
					return switch (command())
					{
						case RETURN:
							RETURN;
						case CONTINUE:
							CONTINUE;
						case BREAK:
							BREAK;
						default:
							linkType = VOID;
					}
				else
					this.pos = endPos;

				return linkType = VOID;

			case IF_ELSE:
				final endPos:Int = next().toInt();
				final endPosElse:Int = next().toInt();

				command();

				var returnValue:Command = -1;

				if (linkID == BOOL_TRUE)
				{
					returnValue = command();
					this.pos = endPosElse;
				}
				else
				{
					this.pos = endPos;
					returnValue = command();
				}

				return switch (returnValue)
				{
					case RETURN:
						RETURN;
					case CONTINUE:
						CONTINUE;
					case BREAK:
						BREAK;
					default:
						linkType;
				}

			case VARIABLE_INT:
				final id:Int = next();
				next();

				command();
				_buffer[id] = cast getValue();

				return linkType;

			case VARIABLE_FLOAT:
				final id:Int = next();

				command();
				floatBuffer[id] = cast getValue();

				return linkType;

			case VARIABLE_STRING:
				final id:Int = next();

				command();
				stringBuffer[id] = cast getValue();

				return linkType;

			case VARIABLE_DYNAMIC:
				final id:Int = next();

				command();
				dynamicBuffer[id] = cast getValue();

				return linkType;

			case CAST_INT_TO_FLOAT:
				command();
				linkID = floatBuffer.push(linkID) - 1;
				return linkType = FLOAT;

			case RETURN:
				command();
				return RETURN;

			case CONTINUE:
				return CONTINUE;

			case BREAK:
				return BREAK;

			case FOR:
				final endPos:Int = next();
				final key:Int = next();

				command();
				final it:Iterator<Dynamic> = makeIterator(getValue());

				final pos:Int = this.pos;

				while (it.hasNext())
				{
					this.pos = pos;
					dynamicBuffer[key] = it.next();

					switch (command())
					{
						case RETURN:
							return RETURN;
						case BREAK:
							this.pos = endPos;
							return linkType = VOID;
						default:
					}
				}
				return linkType = VOID;

			case FOR_KEY_VALUE:
				final endPos:Int = next();
				final key:Int = next();
				final value:Int = next();

				command();
				final it:KeyValueIterator<Dynamic, Dynamic> = makeKeyValueIterator(getValue());

				final pos:Int = this.pos;

				while (it.hasNext())
				{
					this.pos = pos;

					final keyValue = it.next();

					dynamicBuffer[key] = keyValue.key;
					dynamicBuffer[value] = keyValue.value;

					switch (command())
					{
						case RETURN:
							return RETURN;
						case BREAK:
							this.pos = endPos;
							return linkType = VOID;
						default:
					}
				}
				return linkType = VOID;

			case WHILE:
				final endPos:Int = next();

				final pos:Int = this.pos;

				trace(_buffer);

				while (
					{
						command();
						getValue() == true;
					})
				{
					command();

					this.pos = pos;
				}

				this.pos = endPos;

				return linkType = VOID;

			case DO_WHILE:
				final pos:Int = this.pos;

				do
				{
					this.pos = pos;

					command();
				}
				while (
						{
							command();
							getValue() == true;
						});

				return linkType = VOID;

			case INT_ITERATOR:
				final id:Int = next();

				command();
				final from:Int = cast getValue();
				command();
				final to:Int = cast getValue();

				dynamicBuffer[id] = from...to;

				linkID = id;

				return linkType = DYNAMIC;

			case OP_ARITHMETIC_NEGATION:
				command();

				linkID = -cast(getValue(), Int);
				return linkType = INT;

			case OP_ARITHMETIC_NEGATION_FLOAT:
				final id:Int = next();
				command();
				floatBuffer[id] = -cast(getValue(), Float);

				linkID = id;

				return linkType = FLOAT;

			case OP:
				final op = next();
				switch (op)
				{
					case OP_PLUS, OP_MINUS, OP_MULT, OP_DIVISION, OP_MODULO, OP_SHIFT_LEFT, OP_SHIFT_RIGHT, OP_UNSIGNED_SHIFT_RIGHT, OP_BIT_AND, OP_BIT_OR,
						OP_BIT_XOR:
						command();
						var a:Int = linkID;
						command();
						var b:Int = linkID;

						linkType = INT;

						linkID = switch (op)
						{
							case OP_PLUS:
								a + b;
							case OP_MINUS:
								a - b;
							case OP_MULT:
								a * b;
							case OP_SHIFT_LEFT:
								a << b;
							case OP_SHIFT_RIGHT:
								a >> b;
							case OP_UNSIGNED_SHIFT_RIGHT:
								a >>> b;
							case OP_BIT_AND:
								a & b;
							case OP_BIT_OR:
								a | b;
							case OP_BIT_XOR:
								a ^ b;
							default: -1;
						}
						return linkType;
					case OP_DYNAMIC:
						final f:(a:Int, b:Int) -> Dynamic = cast dynamicBuffer[next().toInt()];
						final id:Int = next().toInt();

						command();
						var a:Int = linkID;
						command();
						var b:Int = linkID;

						dynamicBuffer[id] = f(a, b);
						linkID = id;

						return linkType = DYNAMIC;
					case op:
						throw op.toString();
				}
			case OP_FLOAT:
				final id:Int = next();
				final op = next();
				switch (op)
				{
					case OP_PLUS, OP_MINUS, OP_MULT, OP_DIVISION, OP_MODULO:
						command();
						final a:Float = floatBuffer[linkID];
						command();
						final b:Float = floatBuffer[linkID];

						floatBuffer[id] = switch (op)
						{
							case OP_PLUS:
								a + b;
							case OP_MINUS:
								a - b;
							case OP_MULT:
								a * b;
							case OP_DIVISION:
								a / b;
							case OP_MODULO:
								a % b;
							default: -1;
						};

						linkID = id;

						return linkType = FLOAT;
					case OP_DYNAMIC:
						final f:(a:Int, b:Int) -> Dynamic = cast dynamicBuffer[next().toInt()];
						final id:Int = next().toInt();

						command();
						var a:Int = linkID;
						command();
						var b:Int = linkID;

						dynamicBuffer[id] = f(a, b);
						linkID = id;

						return linkType = DYNAMIC;
					case op:
						throw op.toString();
				}

			case STRING_CONCAT:
				final id:Int = next();
				final op = next();

				switch (op)
				{
					case OP_PLUS:
						command();
						final a:Dynamic = getValue();
						command();
						final b:Dynamic = getValue();

						stringBuffer[linkID = id] = Std.string(a) + Std.string(b);
					default:
				}
				return linkType = STRING;
			case OP_NATIVE:
				final id:Int = next();
				final op = next();

				final f:(a:Dynamic, b:Dynamic) -> Dynamic = cast dynamicBuffer[next().toInt()];
				next();

				command();
				var a:Dynamic = getValue();
				command();
				var b:Dynamic = getValue();

				dynamicBuffer[id] = f(a, b);
				linkID = id;

				return linkType = DYNAMIC;

			case PACKAGE:
				scriptPackage = stringBuffer[next().toInt()];
				return linkType = VOID;

			case IMPORT:
				final name:String = stringBuffer[next().toInt()];
				final type = next();
				final id:Int = next();

				if (type == DYNAMIC)
				{
					variables[name] = dynamicBuffer[id];
				}

				return linkType = VOID;

			case USING:
				final id:Int = next();
				final cl:Class<Dynamic> = nativeClassBuffer[id];
				for (field in Type.getClassFields(cl))
				{
					__usings[field] = Reflect.getProperty(cl, field);
				}
				return linkType = VOID;

			case CALL_USING:
				final id:Int = next();
				command();
				final obj:Dynamic = getValue();

				final field:Dynamic = stringBuffer[next().toInt()];

				final func:Dynamic = Reflect.getProperty(obj, field) ?? __usings[field];

				final args:Array<Dynamic> = [obj];

				for (i in 1...next().toInt() + 1)
				{
					command();
					args[i] = getValue();
				}

				dynamicBuffer[id] = Reflect.callMethod(obj, func, args);

				linkID = id;

				return linkType = DYNAMIC;

			case CREATE_OBJECT:
				final id:Int = next();
				var fieldsLength:Int = next();

				final obj:{} = dynamicBuffer[id] = {};

				while (fieldsLength-- != 0)
				{
					final field:String = stringBuffer[next().toInt()];
					command();
					Reflect.setField(obj, field, getValue());
				}
				linkID = id;
				return linkType = DYNAMIC;
			case MAP:
				final id:Int = next();

				var keysNum:Int = next().toInt() - 1;

				command();
				final key:Dynamic = cast getValue();
				command();
				final value:Dynamic = getValue();

				final map:IMap<Dynamic, Dynamic> = switch (Type.typeof(key))
				{
					case TClass(String):
						new haxe.ds.StringMap();
					case TInt:
						new haxe.ds.IntMap();
					case TEnum(_):
						new haxe.ds.EnumValueMap();
					default:
						new haxe.ds.ObjectMap();
				}

				map.set(key, value);

				while (keysNum-- != 0)
				{
					command();
					final key:Dynamic = cast getValue();
					command();
					final value:Dynamic = getValue();
					map.set(key, value);
				}

				dynamicBuffer[id] = map;

				linkID = id;

				return linkType = DYNAMIC;
			case MAP_STRING:
				final id:Int = next();

				var keysNum:Int = next();

				dynamicBuffer[id] = [
					while (keysNum-- != 0)
					{
						command();
						final key:String = cast getValue();
						command();
						final value:Dynamic = getValue();
						key => value;
					}
				];
				linkID = id;

				return linkType = DYNAMIC;
			case MAP_INT:
				final id:Int = next();

				var keysNum:Int = next();

				dynamicBuffer[id] = [
					while (keysNum-- != 0)
					{
						command();
						final key:Int = cast getValue();
						command();
						final value:Dynamic = getValue();
						key => value;
					}
				];
				linkID = id;

				return linkType = DYNAMIC;
			case MAP_ENUM_VALUE:
				final id:Int = next();

				var keysNum:Int = next();

				dynamicBuffer[id] = [
					while (keysNum-- != 0)
					{
						command();
						final key:EnumValue = cast getValue();
						command();
						final value:Dynamic = getValue();
						key => value;
					}
				];
				linkID = id;

				return linkType = DYNAMIC;
			case MAP_OBJECT:
				final id:Int = next();

				var keysNum:Int = next();

				dynamicBuffer[id] = [
					while (keysNum-- != 0)
					{
						command();
						final key:{} = cast getValue();
						command();
						final value:Dynamic = getValue();
						key => value;
					}
				];
				linkID = id;

				return linkType = DYNAMIC;
			case CALL:
				final id:Int = next();

				command();

				var func:Dynamic = getValue();

				var argNum:Int = next();

				var args:Array<Dynamic> = [
					while (argNum-- != 0)
					{
						command();
						getValue();
					}
				];

				#if hl
				dynamicBuffer[id] = Tools.__hl_callMethod(func, args);
				#else
				dynamicBuffer[id] = Reflect.callMethod(null, func, args);
				#end

				linkID = id;

				isSuperCall = false;

				return linkType = DYNAMIC;
			case NEW:
				final id:Int = next();
				final type:String = stringBuffer[next().toInt()];

				var argNum:Int = next();

				final args:Array<Dynamic> = [
					while (argNum-- != 0)
					{
						command();
						getValue();
					}
				];

				dynamicBuffer[id] = cnew(type, args);

				linkID = id;

				return linkType = DYNAMIC;

			case ARRAY:
				final id:Int = next();

				var fieldsLength:Int = next();

				dynamicBuffer[id] = [
					while (fieldsLength-- != 0)
					{
						command();
						getValue();
					}
				];

				linkID = id;

				return linkType = DYNAMIC;

			case ARRAY_GET:
				final id:Int = next();
				command();
				final arr:Array<Dynamic> = cast getValue();
				command();
				final index:Int = cast getValue();

				dynamicBuffer[id] = arr[index];

				linkID = id;

				return linkType = DYNAMIC;

			case ARRAY_SET:
				command();
				final arr:Array<Dynamic> = cast getValue();
				command();
				final index:Int = cast getValue();
				command();
				arr[index] = getValue();

				return linkType;

			case CONSTRUCTOR:
				final id:Int = next();

				final endPos:Int = next();
				final argNum:Int = next();
				final startPos:Int = this.pos;
				this.pos = endPos;

				linkID = id;

				variables['__constructor'] = dynamicBuffer[id] = function(args:Array<Dynamic>):rulescript.RuleScriptAccess.ConstructorAccess

				{
					final lastPos = this.pos;

					this.pos = startPos;

					if (argNum != 0)
					{
						var i:Int = 0;
						do
						{
							final argId:Int = next();
							dynamicBuffer[argId] = args[i];
						}
						while (i++ <= argNum);
					}

					return {
						pre: () -> command(),

						getSuperArgs: () ->
						{
							var superArgNum:Int = next();

							[
								while (superArgNum-- > 0)
								{
									command();
									getValue();
								}
							];
						},
						post: () ->
						{
							command();
							this.pos = lastPos;
						}
					};
				};

				return linkType = DYNAMIC;

			case FUNCTION:
				final id:Int = next();

				final endPos:Int = next();
				final name:String = stringBuffer[next().toInt()];
				final argNum:Int = next();
				final startPos:Int = this.pos;
				this.pos = endPos;

				var f:Dynamic = function(args:Array<Dynamic>):Dynamic
				{
					final lastPos = this.pos;

					this.pos = startPos;

					if (argNum != 0)
					{
						var i:Int = 0;
						do
						{
							final argId:Int = next();
							dynamicBuffer[argId] = args[i];
						}
						while (i++ <= argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;
					return v;
				}

				#if hl
				var f:Dynamic = switch (argNum)
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
				#else
				var f = Reflect.makeVarArgs(f);
				#end

				variables[name] = dynamicBuffer[id] = f;
				linkID = id;

				return linkType = DYNAMIC;
			case LOCAL_FUNCTION:
				final id:Int = next();

				final endPos:Int = next();
				final name:String = stringBuffer[next().toInt()];
				final argNum:Int = next();
				final startPos:Int = this.pos;
				this.pos = endPos;

				var f:Dynamic = function(args:Array<Dynamic>):Dynamic
				{
					final lastPos = this.pos;

					this.pos = startPos;

					if (argNum != 0)
					{
						var i:Int = 0;
						do
						{
							final argId:Int = next();
							dynamicBuffer[argId] = args[i];
						}
						while (i++ <= argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;
					return v;
				}

				#if hl
				var f:Dynamic = switch (argNum)
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
				#else
				var f = Reflect.makeVarArgs(f);
				#end

				variables[name] = dynamicBuffer[id] = f;
				linkID = id;

				return linkType = DYNAMIC;
			case ANON_FUNCTION:
				final id:Int = next();
				final endPos:Int = next();
				final argNum:Int = next();
				final startPos:Int = this.pos;
				this.pos = endPos;

				var f:Dynamic = function(args:Array<Dynamic>):Dynamic
				{
					final lastPos = this.pos;

					this.pos = startPos;

					if (argNum != 0)
					{
						var i:Int = 0;
						do
						{
							final argId:Int = next();
							dynamicBuffer[argId] = args[i];
						}
						while (i++ <= argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;
					return v;
				}

				#if hl
				var f:Dynamic = switch (argNum)
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
				#else
				var f = Reflect.makeVarArgs(f);
				#end

				dynamicBuffer[id] = f;
				linkID = id;

				return linkType = DYNAMIC;

			case GET_NATIVE:
				final id:Int = next();
				command();
				final o:Dynamic = getValue();
				if (o == null)
					throw 'Null access';

				dynamicBuffer[id] = Reflect.getProperty(o, stringBuffer[next().toInt()]);
				linkID = id;

				if (o == superInstance)
					isSuperCall = true;

				return linkType = DYNAMIC;

			case GET_SCRIPTED_TYPE:
				final id:Int = next();
				command();
				final v:Dynamic = getValue();

				final o:ScriptedClass = cast v;
				dynamicBuffer[id] = o.getVariable(stringBuffer[next().toInt()]);
				linkID = id;

				return linkType = DYNAMIC;

			case IDENT_NATIVE:
				final id:Int = linkID = next();
				final name:String = stringBuffer[next().toInt()];

				dynamicBuffer[id] = variables[name];

				return linkType = DYNAMIC;
			case LINK:
				var type = next();
				linkType = type;
				linkID = next();
				return linkType;
			case BUFFER_LINK:
				linkID = _buffer[next().toInt()];
				return linkType = INT;
			case NULL:
				return linkType = NULL;
			case command:
				throw command.toString();
		}
	}

	function makeIterator(obj:Dynamic):Iterator<Dynamic>
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (obj.iterator != null)
			obj = obj.iterator();
		#elseif js
		// don't use try/catch (very slow)
		if (obj is Array)
			return (obj : Array<Dynamic>).iterator();
		if (obj.iterator != null)
			obj = obj.iterator();
		#else
		try
			obj = obj.iterator()
		catch (e:Dynamic) {};
		#end
		return cast obj;
	}

	function makeKeyValueIterator(obj:Dynamic):KeyValueIterator<Dynamic, Dynamic>
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (obj.keyValueIterator != null)
			obj = obj.keyValueIterator();
		#else
		if (obj.keyValueIterator != null)
			obj = obj.keyValueIterator();
		#end

		#if hl
		if (obj is haxe.ds.StringMap)
			obj = cast(obj, haxe.ds.StringMap<Dynamic>).keyValueIterator();
		#end

		return obj;
	}

	function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		var c:Dynamic = Type.resolveClass(cl);

		c ??= RuleScript.resolveScript(cl);
		c ??= variables.get(cl);

		if (c is ScriptedClass)
			return cast(c, ScriptedClass).createInstance(args);

		#if hl
		return Reflect.isFunction(c) ? Tools.__hl_callMethod(c, args) : c is Class ? Tools.__hl_createInstance(c, args) : c;
		#else
		return Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : c is Class ? Type.createInstance(c, args) : c;
		#end
	}

	private function set_scriptPackage(value:String):String
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

	private function set_superInstance(v:Dynamic):Dynamic
	{
		return superInstance = v;
	}

	private function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
	{
		return errorHandler = v;
	}
}

class InterpAccess extends RuleScriptAccess
{
	var interp:BytecodeInterp;

	public function new(interp:BytecodeInterp)
	{
		this.interp = interp;
	}

	override function getVariables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	override function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
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

	override function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		return if (variableExists(name))
		{
			#if hl
			Tools.__hl_callMethod(interp.variables[name], args);
			#else
			Reflect.callMethod(null, interp.variables[name], args);
			#end
		}
		else
			null;
	}

	override function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		return #if hl
			Tools.__hl_callMethod(interp.variables[name], args);
		#else
			Reflect.callMethod(null, interp.variables[name], args);
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

	override function get_isSuperCall():Bool
	{
		return interp.isSuperCall;
	}

	override function get_hasConstructor():Bool
	{
		return variableExists('__constructor');
	}

	override function createConstructor(args:Array<Dynamic>):rulescript.RuleScriptAccess.ConstructorAccess
	{
		return getVariable('__constructor')(args);
	}
}

@:access(rulescript.BytecodeInterp)
class Converter
{
	/**
	 * Metadata name => (arguments:Array<Expr>,e:Expr) -> Expr
	 */
	public var onMeta:Map<String, (args:Array<Expr>, e:Expr) -> Expr> = [];

	public var interp(default, null):BytecodeInterp;

	public function new(interp:BytecodeInterp)
	{
		this.interp = interp;
	}

	var variables:Map<String, VarType> = [];

	public function convertExpr(e:Expr)
	{
		final buffer:Array<Command> = interp._buffer;

		inline function add(command:Command):Int
			return buffer.push(command);

		inline function addLink<T>(type:Command, o:T, createNew:Bool = false):Void
			add(link(type, o, createNew));

		variables.clear();

		final lastValues:Array<{name:String, t:VarType}> = [];

		function regenVariables(num:Int)
		{
			while (lastValues.length > num)
			{
				final v = lastValues.pop();
				variables[v.name] = v.t;
			}
		}

		if (interp.superInstance != null)
		{
			final fields:Array<String> = if (Type.getClass(interp.superInstance) is Class)
				Type.getInstanceFields(Type.getClass(interp.superInstance));
			else
				Reflect.fields(interp.superInstance);

			for (field in fields)
				variables[field] = TNativeField;
		}

		for (key => value in interp.variables)
		{
			variables[key] = TId(DYNAMIC, link(DYNAMIC, value));
		}

		var imports:Map<String, VarType> = [];
		var usings:Array<String> = [];

		var depth:Int = -1;
		function ce(e:Expr):Void // convert expr
		{
			switch (e.getExpr())
			{
				case EBlock(exprs):
					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					for (expr in exprs)
					{
						switch (expr.getExpr())
						{
							case EVar(name, t, e, global, isFinal):
								lastValues.push({name: name, t: variables[name]});
								variables.set(name, isFinal ? TFinal(TUnknown) : TUnknown);

							case EFunction(args, e, name, ret):
								lastValues.push({name: name, t: variables[name]});
								variables.set(name, TFunction(null));
							default:
						}
					}

					add(BLOCK);
					add(exprs.length);
					for (e in exprs)
						ce(e);

					depth = oldDepth;

					regenVariables(oldVariables);
				case EConst(c):
					add(CONST);
					switch (c)
					{
						case CInt(v):
							add(INT);
							add(v);
						case CFloat(f):
							add(FLOAT);
							addLink(FLOAT, f);
						case CString(s):
							add(STRING);
							addLink(STRING, s);
						default: add(NULL);
					}

				case EPackage(path):
					add(PACKAGE);
					addLink(STRING, path);

				case EReturn(e):
					add(RETURN);
					ce(e);

				case ECheckType(e, _):
					ce(e);

				case EVar(name, t, expr, global, isFinal):
					final type:VarType = t != null ? typeofCType(t) : typeof(expr);

					final isMap:Bool = type.match(TMap(_));

					lastValues.push({name: name, t: variables[name]});

					var varType = switch (type)
					{
						case TClass(String):
							add(VARIABLE_STRING);
							final id = link(STRING, null, true);
							add(id);

							TId(STRING, id);

						case TFloat:
							add(VARIABLE_FLOAT);
							final id = link(FLOAT, 0.0, true);
							add(id);

							TId(FLOAT, id);

						case TInt:
							add(VARIABLE_INT);
							final id = add(-1);
							add(-1);
							buffer[id - 1] = id;

							TId(INT, id);

						case TBool:
							add(VARIABLE_BOOL);
							final id = add(-1) - 1;
							buffer[id] = id;
							add(id);

							TBool;

						default:
							add(VARIABLE_DYNAMIC);
							final id = link(DYNAMIC, null, true);
							add(id);

							TId(type == TObject ? OBJECT : DYNAMIC, id);
					}

					variables.set(name, isFinal ? TFinal(varType) : varType);

					if (expr != null)
					{
						if (isMap && expr.getExpr().match(EArrayDecl(_)))
						{
							switch (type)
							{
								case TMap(TClass(String)):
									add(MAP_STRING);
								case TMap(TInt):
									add(MAP_INT);
								case TMap(TDynamic):
									add(MAP_OBJECT);
								case TMap(TEnum):
									add(MAP_ENUM_VALUE);
								default:
									throw 'Unknown type';
							}
							switch (expr.getExpr())
							{
								case EArrayDecl(e):
									ce(EMapDecl(e).toExpr());
								default:
							}
						}
						else
							ce(expr);
					}
					else
					{
						#if static
						switch (type)
						{
							case TInt:
								ce(EConst(CInt(0)).toExpr());
							case TFloat:
								ce(EConst(CFloat(0.0)).toExpr());
							case TBool:
								ce(EIdent('false').toExpr());
							default:
								add(NULL);
						}
						#else
						add(NULL);
						#end
					}

				case EIdent(v):
					switch (v)
					{
						case 'true':
							add(BOOL_TRUE);
						case 'false':
							add(BOOL_FALSE);
						case 'null':
							add(NULL);
						case 'super':
							add(SUPER);
						case _ if (!variables.exists(v)):
							add(IDENT_NATIVE);
							addLink(DYNAMIC, null, true);
							addLink(STRING, v);

						default:
							switch (variables[v])
							{
								case TClass(c):
									add(LINK);
									add(CLASS);
									addLink(CLASS, c);

								case TFunction(f) if (f != null):
									add(LINK);
									add(FUNCTION);
									addLink(FUNCTION, f);

								case TId(INT, id), TFinal(TId(INT, id)):
									add(BUFFER_LINK);
									add(id);

								case TId(type, id), TFinal(TId(type, id)):
									add(LINK);
									add(type);
									add(id);

								case TNativeField:
									add(NATIVE_FIELD);
									addLink(STRING, v);
									addLink(DYNAMIC, null, true);

								default:
									add(IDENT_NATIVE);
									addLink(DYNAMIC, null, true);
									addLink(STRING, v);
							}
					}
				case EField(e, f):
					add(typeof(e) == TScriptedClass ? GET_SCRIPTED_TYPE : GET_NATIVE);

					addLink(DYNAMIC, null, true);
					ce(e);
					addLink(STRING, f);

				case EParent(e):
					ce(e);

				case ETypeVarPath(path):
					if (!variables.exists(path[0]))
					{
						final typePath:String = path.join('.');
						var field:String = null;

						final type:Dynamic = resolveType(typePath) ?? {
							field = path[path.length - 1];
							resolveType(typePath.substring(0, typePath.lastIndexOf('.')));
						}

						switch (toVarType(type))
						{
							case TClass(_) | TInstance(_):
								add(LINK);
								add(DYNAMIC);
								addLink(DYNAMIC, type);
							case TObject if (field != null):
								if (Tools.isEnum(type))
								{
									add(LINK);
									add(DYNAMIC);
									addLink(DYNAMIC, {
										if (Type.getEnumConstructs(type).contains(field))
										{
											if (Type.allEnums(type).map(_ -> Std.string(_)).contains(field))
												Type.createEnum(type, field);
											else
												Reflect.makeVarArgs((args:Array<Dynamic>) -> Type.createEnum(type, field, args));
										}
										else
											null;
									});
								}
								else
								{
									add(GET_NATIVE);
									addLink(DYNAMIC, null, true);

									add(LINK);
									add(DYNAMIC);
									addLink(DYNAMIC, type);

									addLink(STRING, field);
								}

							case TObject:
								add(LINK);
								add(DYNAMIC);
								addLink(DYNAMIC, type);
							case type:
								throw type;
						}
						return;
					}

					var e = EIdent(path[0]).toExpr();

					for (i in 1...path.length)
						e = EField(e, path[i]).toExpr();

					ce(e);
				case EObject(fields):
					add(CREATE_OBJECT);
					addLink(DYNAMIC, null, true);

					add(fields.length);

					for (field in fields)
					{
						addLink(STRING, field.name);
						ce(field.e);
					}
				case ECall(e, params):
					var isUsing:Bool = false, fieldName:String = null;

					for (field in usings)
					{
						switch (e.getExpr())
						{
							case EField(expr, f):
								if (field == f)
								{
									isUsing = true;
									e = expr;
									fieldName = f;
								}
							default:
						}
					}

					add(isUsing ? CALL_USING : CALL);

					addLink(DYNAMIC, null, true);

					ce(e);

					if (isUsing)
						addLink(STRING, fieldName);

					add(params.length);
					for (param in params)
						ce(param);

				case EImport(name, _, alias, func):
					var type:Dynamic = resolveType(name);
					if (func != null)
						type = Reflect.getProperty(type, func);

					final id:String = alias ?? func ?? name.substring(name.lastIndexOf('.') + 1, name.length);

					imports[id] = toVarType(type);

					add(IMPORT);
					addLink(STRING, id);

					lastValues.push({name: id, t: variables[id]});
					variables[id] = imports[id];

					if (type is Class)
					{
						add(CLASS);
						addLink(CLASS, type);
					}
					else
					{
						add(Reflect.isFunction(type) ? FUNCTION : DYNAMIC);
						addLink(DYNAMIC, type);
					}

				case EUsing(name):
					final type:Class<Dynamic> = resolveType(name);

					if (type is Class)
					{
						for (field in Type.getClassFields(type))
							if (!usings.contains(field) && Reflect.isFunction(Reflect.field(type, field)))
								usings.push(field);

						add(USING);

						addLink(CLASS, type);
					}

				case EFor(key, iterator, e, value):
					add(value == null ? FOR : FOR_KEY_VALUE);

					final endId:Int = add(-1) - 1; // for end ID

					final keyId:Int = link(DYNAMIC, null, true);
					add(keyId);

					final valueId:Int = if (value != null)
					{
						final id = link(DYNAMIC, null, true);
						add(id);
						id;
					}
					else
						-1;

					ce(iterator);

					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					lastValues.push({name: key, t: variables[key]});
					variables[key] = TId(DYNAMIC, keyId);

					if (value != null)
					{
						lastValues.push({name: value, t: variables[value]});
						variables[value] = TId(DYNAMIC, valueId);
					}

					ce(e);

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[endId] = buffer.length;

				case EIf(cond, e1, e2), ETernary(cond, e1, e2):
					if (e2 == null)
					{
						add(IF);
						final id:Int = add(-1) - 1; // If end ID

						ce(cond);

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;

						ce(e1);

						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[id] = buffer.length;
					}
					else
					{
						add(IF_ELSE);

						final id:Int = add(-1) - 1; // If end ID
						final idElse:Int = add(-1) - 1; // Else end ID

						ce(cond);

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;
						ce(e1);
						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[id] = buffer.length;

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;
						ce(e2);
						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[idElse] = buffer.length;
					}

				case EFunction(args, e, name, ret):
					add(switch (name)
					{
						case null: ANON_FUNCTION;
						case 'new': CONSTRUCTOR;
						default: (depth == 0 ? FUNCTION : LOCAL_FUNCTION);
					});

					addLink(DYNAMIC, null, true); // Return value ID

					final id:Int = add(-1) - 1; // Function end ID

					if (name != null && name != 'new')
						addLink(STRING, name);
					add(args.length);

					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					for (arg in args)
					{
						final argId = link(DYNAMIC, null, true);

						lastValues.push({name: arg.name, t: variables[arg.name]});
						variables[arg.name] = TId(DYNAMIC, argId);

						add(argId);
					}

					if (name == 'new')
					{
						final exprs = switch (rulescript.Tools.getExpr(e))
						{
							case EBlock(exprs):
								exprs;
							default:
								null;
						}

						var superID:Int = 0;

						for (expr in exprs)
						{
							switch (rulescript.Tools.getExpr(expr))
							{
								case ECall(e, _):
									if (rulescript.Tools.getExpr(e).match(EIdent('super')))
										break;
								default:
									null;
							}
							superID++;
						}

						final superCallArgs:Array<Expr> = switch (rulescript.Tools.getExpr(exprs[superID]))
						{
							case ECall(_, params): params;
							default: null;
						};

						ce(EBlock(exprs.slice(0, superID)).toExpr());

						add(superCallArgs.length);

						for (expr in superCallArgs)
						{
							ce(expr);
						}

						ce(EBlock(exprs.slice(superID + 1)).toExpr());
					}
					else
					{
						ce(e);
					}

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[id] = buffer.length;

					if (name != null)
					{
						lastValues.push({name: name, t: variables[name]});
						variables.set(name, TFunction(null));
					}

				case EMapDecl(exprs):
					final mapType:Command = if (buffer.length > 0)
						buffer[buffer.length - 1]
					else
						0;

					addLink(DYNAMIC, null, true);

					add(exprs.length);

					for (e in exprs)
						switch (e.getExpr())
						{
							case EBinop("=>", key, value):
								ce(key);
								ce(value);
							default:
								throw 'Invalid expression';
						}

				case EArrayDecl(exprs):
					if ((exprs.length > 0 && exprs[0].getExpr().match(EBinop("=>", _))))
					{
						add(MAP);
						ce(EMapDecl(exprs).toExpr());
					}
					else
					{
						add(ARRAY);
						addLink(DYNAMIC, null, true);
						add(exprs.length);

						for (expr in exprs)
							ce(expr);
					}

				case EBinop(op, e1, e2):
					if (op != '=' && typeof(e) != TBool && op.endsWith('='))
					{
						ce(EBinop('=', e1, EBinop(op.substr(0, -1), e1, e2).toExpr()).toExpr());
						return;
					}

					final type = typeof(e);

					if (op != '=')
						switch (type)
						{
							case TInt:
								add(OP);
							case TFloat:
								add(OP_FLOAT);
								addLink(FLOAT, 0., true);
							case TDynamic:
								add(OP_NATIVE);
								addLink(DYNAMIC, null, true);
							case TClass(String):
								add(STRING_CONCAT);
								addLink(STRING, null, true);
							case TClass(IntIterator):
								add(INT_ITERATOR);
								addLink(DYNAMIC, null, true);
								ce(e1);
								ce(e2);
								return;
							case TBool:
								final isNative:Bool = switch (op)
								{
									case '==', '!=', '&&', '||', '>', '<', '>=', '<=':
										false;
									default:
										true;
								}

								if (isNative)
								{
									add(OP_NATIVE);
									addLink(DYNAMIC, null, true);
								}
								else
								{
									add(switch (op)
									{
										case '==': EQUAL;
										case '!=': NOT_EQUAL;
										case '&&': AND;
										case '||': OR;
										case '>': OP_GT;
										case '<': OP_LT;
										case '>=': OP_GT_EQUAL;
										case '<=': OP_LT_EQUAL;
										default:
											throw 'Unknown operator "$op"';
									});
									ce(e1);
									ce(e2);

									return;
								}
							case type:
								throw type;
						}
					else
					{
						switch (e1.getExpr())
						{
							case EIdent(v):
								if (variables.exists(v) && variables[v].match(TId(_)))
									switch (variables[v])
									{
										case TId(type, id):
											add(SET);
											add(type);
											add(id);
											ce(e2);
										case type:
											throw type;
									}
								else
								{
									add(SET_NATIVE);
									addLink(DYNAMIC, null, true);
									addLink(STRING, v);
									ce(e2);

									lastValues.push({name: v, t: variables[v]});
									variables[v] = typeof(e2);
								}
							case EField(e, f):
								switch (typeof(e))
								{
									case TObject:
										add(OBJECT_SET);
									default:
										add(OBJECT_SET_PROP);
								}

								addLink(STRING, f);
								ce(e);
								ce(e2);

							case EArray(e, index):
								add(ARRAY_SET);
								ce(e);
								ce(index);
								ce(e2);
							default:
								throw 'Invalid assign';
						}
						return;
					}

					if (type == TDynamic)
					{
						if (interp.binops.exists(op))
						{
							add(OP_DYNAMIC);
							addLink(DYNAMIC, interp.binops[op]);
							addLink(DYNAMIC, null, true);
						}
					}
					else
					{
						switch (op)
						{
							case '+':
								add(OP_PLUS);
							case '-':
								add(OP_MINUS);
							case '*':
								add(OP_MULT);
							case '/':
								add(OP_DIVISION);
							case '%':
								add(OP_MODULO);
							case '<<':
								add(OP_SHIFT_LEFT);
							case '>>':
								add(OP_SHIFT_RIGHT);
							case '>>>':
								add(OP_UNSIGNED_SHIFT_RIGHT);
							case '&':
								add(OP_BIT_AND);
							case '|':
								add(OP_BIT_OR);
							case '^':
								add(OP_BIT_XOR);
							case _ if (interp.binops.exists(op)):
								add(OP_DYNAMIC);
								addLink(DYNAMIC, interp.binops[op]);
								addLink(DYNAMIC, null, true);
							default:
								throw 'Unknown operator "$op"';
						}
					}

					if (type == TFloat)
					{
						if (typeof(e1) == TInt)
							add(CAST_INT_TO_FLOAT);

						ce(e1);

						if (typeof(e2) == TInt)
							add(CAST_INT_TO_FLOAT);

						ce(e2);
					}
					else
					{
						ce(e1);
						ce(e2);
					}

				case EUnop(op, prefix, e):
					switch (op)
					{
						case '-':
							if (typeof(e) == TInt)
							{
								add(OP_ARITHMETIC_NEGATION);
							}
							else
							{
								add(OP_ARITHMETIC_NEGATION_FLOAT);
								addLink(FLOAT, 0.0, true);
							}
							ce(e);
						case '!':
							add(NOT);
							ce(e);
						case '~':
							add(OP_BIT_NEGATION);
							ce(e);
						case '++', '--':
							switch (e.getExpr())
							{
								case EIdent(v):
									if (prefix)
									{
										ce(EBinop('=', e, EBinop('+', e, EConst(CInt(op == '++' ? 1 : -1)).toExpr()).toExpr()).toExpr());
									}
									else
									{
										if (typeof(e) == TInt)
											add(op == '++' ? OP_POST_INCREMENT : OP_POST_DECREMENT);
										else
										{
											add(op == '++' ? OP_POST_INCREMENT_FLOAT : OP_POST_DECREMENT_FLOAT);
											addLink(FLOAT, 0.0, true);
										}

										switch (e.getExpr())
										{
											case EIdent(v):
												if (variables.exists(v))
													switch (variables[v])
													{
														case TId(type, id):
															add(type);
															add(id);
															return;
														case type:
															throw type;
													}
											default:
										}
									}
								case EField(e, f):
								case EArray(e, index):
								default:
									throw 'Invalid operator "$op"';
							}
					}
				case ENew(cl, params):
					add(NEW);
					addLink(DYNAMIC, null, true);
					addLink(STRING, cl);
					add(params.length);
					for (param in params)
						ce(param);
				case EArray(e, index):
					add(ARRAY_GET);
					addLink(DYNAMIC, null, true);
					ce(e);
					ce(index);
				case EMeta(name, args, e):
					if (onMeta.exists(name))
						ce(onMeta[name](args, e));
				case EContinue:
					add(CONTINUE);
				case EBreak:
					add(BREAK);
				case EUntyped(e):
					ce(e);
				case EWhile(cond, e):
					add(WHILE);

					final endId:Int = add(-1) - 1; // for end ID

					ce(cond);
					ce(e);

					buffer[endId] = buffer.length;
				case EDoWhile(cond, e):
					add(DO_WHILE);

					ce(e);
					ce(cond);

				default:
					throw 'Unsupported expression "${e.getExpr()}"';
			}
		}
		ce(switch (e.getExpr())
		{
			case EBlock(_):
				e;
			default:
				EBlock([e]).toExpr();
		});
	}

	function toVarType(type:Dynamic):VarType
	{
		if (type is Class)
			return TClass(type);

		return switch (Type.typeof(type))
		{
			case TFunction:
				return TFunction(type);
			case TClass(c):
				return TInstance(TClass(c));
			case TEnum(e):
				return TEnum;
			case TObject:
				return TObject;
			default:
				return TUnknown;
		}
	}

	private function getExprValue(e:Expr):Dynamic
	{
		return switch (Tools.getExpr(e))
		{
			case EConst(c):
				switch (c)
				{
					case CInt(v): v;
					case CFloat(f): f;
					case CString(s): s;
					default: null;
				}
			case EIdent('null'):
				TNull;
			default:
				null;
		}
	}

	private function resolveType(path:String):Dynamic
	{
		var t:Dynamic = RuleScript.resolveScript(path);

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

	private function typeof(e:Expr):VarType
	{
		return switch (e.getExpr())
		{
			case EVar(_):
				TVoid;
			case ECheckType(_, t):
				TDynamic;
			case EConst(c):
				switch (c)
				{
					case CInt(_):
						TInt;
					case CFloat(_):
						TFloat;
					case CString(_):
						TClass(String);
				}
			case EBinop(op, e1, e2):
				switch (op)
				{
					case '/':
						final t1 = typeof(e1), t2 = typeof(e2);

						switch ([t1, t2])
						{
							case [TInt, TInt] | [TInt, TFloat] | [TFloat, TInt] | [TFloat, TFloat]:
								TFloat;
							default:
								TDynamic;
						}
					case '+', "-", "*", "%":
						final t1 = typeof(e1), t2 = typeof(e2);

						switch ([t1, t2])
						{
							case [TInt, TInt]:
								TInt;
							case [TClass(String), _] | [_, TClass(String)]:
								TClass(String);
							case [TInt, TFloat] | [TFloat, TInt] | [TFloat, TFloat]:
								TFloat;
							default:
								TDynamic;
						}
					case '<<', '>>', '>>>', '&', '|', '^':
						final t1 = typeof(e1), t2 = typeof(e2);

						if (t1 == TInt && t2 == TInt)
							TInt;
						else
							TDynamic;
					case 'is', '&&', '||', '==', '!=', '>=', '<=', '>', '<':
						TBool;
					case '=':
						typeof(e2);
					case '...':
						TClass(IntIterator);
					default:
						TDynamic;
				}
			case EParent(e):
				typeof(e);
			case EIdent(v):
				switch (v)
				{
					case 'true', 'false':
						return TBool;
					case 'null':
						return TNull;
					case 'super':
						return TDynamic;
					default:
						switch (variables[v])
						{
							case TId(type, id):
								switch (type)
								{
									case STRING:
										TClass(String);
									case INT:
										TInt;
									case FLOAT:
										TFloat;
									case DYNAMIC:
										TDynamic;
									case OBJECT:
										TObject;
									default:
										throw 'Unknown type "$type"';
								}
							case TInstance(TClass(ScriptedClass)):
								return TScriptedClass;
							case null if (!variables.exists(v)):
								throw 'Unknown variable "$v"';
							case t:
								t;
						}
				}

			case EArrayDecl(e):
				if (e[0] != null && e[0].getExpr().match(EBinop('=>', _, _)))
				{
					TMap(typeof(e[0]));
				}
				else
					TClass(Array);

			case ETypeVarPath(path):
				if (!variables.exists(path[0]))
				{
					final typePath:String = path.join('.');
					var field:String = null;

					final type:Dynamic = resolveType(typePath) ?? {
						field = path[path.length - 1];
						resolveType(typePath.substring(0, typePath.lastIndexOf('.')));
					}

					return switch (toVarType(type))
					{
						case TEnum:
							(field != null) ? TEnumValue : TEnum;
						case TInstance(TClass(ScriptedClass)):
							TScriptedClass;
						default:
							TDynamic;
					};
				}
				else
					TDynamic;
			case ENew(cl, params):
				TInstance(toVarType(resolveType(cl)));
			case EObject(_):
				TObject;
			case EFunction(_):
				TFunction(null);
			case EField(_), ECall(_), EArray(_):
				TDynamic;
			default:
				throw e;
		}
	}

	private function typeofCType(type:CType):VarType
	{
		return switch (type)
		{
			case CTPath(['Map'], params):
				switch (params[0])
				{
					case CTPath(path, _):
						switch (path[0])
						{
							case 'String':
								TMap(TClass(String));
							case 'Int':
								TMap(TInt);
							case _ if ((variables.exists(path[0]) && Tools.isEnum(variables[path[0]]))
								|| Tools.isEnum(resolveType(path.join('.')))):
								TMap(TEnum);
							default:
								throw 'Invalid map params';
						}
					case CTAnon(_):
						TMap(TDynamic);
					default:
						throw 'Invalid map params';
				}
			case CTPath(['Int'], null):
				TInt;
			case CTPath(['Float'], null):
				TFloat;
			case CTPath(['String'], null):
				TClass(String);
			case CTPath(['Bool'], null):
				TBool;
			default:
				TDynamic;
		}
	}

	private inline function link<T>(type:Command, o:T, createNew:Bool = false):Int
	{
		final buffer:Array<T> = switch (type)
		{
			case FLOAT:
				cast interp.floatBuffer;
			case STRING:
				cast interp.stringBuffer;
			case CLASS:
				cast interp.nativeClassBuffer;
			default:
				cast interp.dynamicBuffer;
		}

		return if (createNew)
			buffer.push(o) - 1;
		else
		{
			var id:Int = buffer.indexOf(cast o);
			if (id == -1)
				id = buffer.push(cast o) - 1;
			id;
		}
	}
}

enum VarType
{
	TScriptedClass;
	TNativeField;
	TClass(c:Class<Dynamic>);
	TFunction(f:Dynamic);
	TId(type:Command, ?id:Int);
	TFloat;
	TInt;
	TBool;
	TEnum;
	TEnumValue;
	TFinal(t:VarType);
	TMap(type:VarType);
	TInstance(type:VarType);
	TObject;
	TNull;
	TDynamic;
	TVoid;
	TUnknown;
}
