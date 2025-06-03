package rulescript.interps;

import haxe.Constraints.IMap;
import hscript.Expr;
import rulescript.RuleScript.IInterp;
import rulescript.interps.bytecode.Command;
import rulescript.interps.bytecode.Converter;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.Property;
import rulescript.types.ScriptedTypeUtil;

using StringTools;
using rulescript.Tools;

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

	public var staticOptimization:Bool = true;

	/**
	 * used by the interpreter when type is dynamic
	 */
	public var binops:Map<String, (Dynamic, Dynamic) -> Dynamic> = [];

	public var lineInfo:Bool = true;

	var converter:Converter;

	var curLine:Int = 0;

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
				fileName: scriptName ?? "rulescript",
				lineNumber: lineInfo ? curLine : 0
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

			case LINE:
				curLine = next();

				command();

				return linkType;

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

			case THROW:
				command();
				throw getValue();

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
				final value:Dynamic = getValue();

				switch (type)
				{
					case STRING:
						stringBuffer[id] = value;
					case INT:
						_buffer[id] = value;
					case BOOL:
						_buffer[id] = value;
					case FLOAT:
						floatBuffer[id] = value;
					case DYNAMIC:
						final obj:Dynamic = dynamicBuffer[id];
						if (obj is Property)
							cast(obj, Property).value = value;
						else
							dynamicBuffer[id] = value;
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
				final endId:Int = next();

				command();

				if (getValue())
				{
					command();
					linkID = (getValue()) ? BOOL_TRUE : BOOL_FALSE;
				}
				else
				{
					linkID = BOOL_FALSE;
					this.pos = endId;
				}

				return linkType = BOOL;

			case OR:
				final endId:Int = next();

				command();

				if (getValue())
				{
					linkID = BOOL_TRUE;
					this.pos = endId;
				}
				else
				{
					command();
					linkID = (getValue()) ? BOOL_TRUE : BOOL_FALSE;
				}

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

				return VOID;

			case VARIABLE_FLOAT:
				final id:Int = next();

				command();
				floatBuffer[id] = cast getValue();

				return VOID;

			case VARIABLE_STRING:
				final id:Int = next();

				command();
				stringBuffer[id] = cast getValue();

				return VOID;

			case VARIABLE_DYNAMIC:
				final id:Int = next();

				command();
				dynamicBuffer[id] = cast getValue();

				return VOID;

			case CREATE_PROPERTY:
				final id:Int = next();

				var getF:PropertyAccess = switch (next())
				{
					case PROP_DEFAULT:
						DEFAULT;
					case PROP_CALLBACK:
						command();
						GET(getValue());
					case PROP_NULL:
						NULL;
					case PROP_DYNAMIC:
						command();
						DYNAMIC(getValue());
					case PROP_NEVER:
						NEVER;
					default:
						null;
				}

				var setF:PropertyAccess = switch (next())
				{
					case PROP_DEFAULT:
						DEFAULT;
					case PROP_CALLBACK:
						command();

						var value:Dynamic->Dynamic = cast getValue();

						SET(value);
					case PROP_NULL:
						NULL;
					case PROP_DYNAMIC:
						command();
						DYNAMIC(getValue());
					case PROP_NEVER:
						NEVER;
					default:
						null;
				}

				command();
				var lazyF:() -> Dynamic = cast getValue();

				final prop = new Property(getF, setF);
				prop._lazyValue = lazyF;
				dynamicBuffer[id] = prop;

				return VOID;

			case CAST_INT_TO_FLOAT:
				command();
				linkID = floatBuffer.push(linkID) - 1;
				return linkType = FLOAT;

			case CAST_TO_INT:
				command();
				linkID = cast(getValue(), Int);
				return linkType = INT;

			case RETURN:
				command();
				return RETURN;

			case CONTINUE:
				return CONTINUE;

			case BREAK:
				return BREAK;

			case TRY:
				final tryEndPos:Int = next();
				final endPos:Int = next();

				final vId:Int = next();

				try
				{
					command();
					this.pos = endPos;
				}
				catch (v:Dynamic)
				{
					this.pos = tryEndPos;

					dynamicBuffer[vId] = v;
					command();
				}

				return linkType;

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

				final argNum:Int = next();
				final isRest:Bool = next() == PARAM_REST;
				final args:Array<Dynamic> = [obj];

				for (i in 1...argNum + 1)
				{
					command();
					args[i] = getValue();
				}

				if (isRest)
				{
					for (i in cast(args.pop(), Array<Dynamic>))
					{
						args.push(i);
					}
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

				final func:Dynamic = getValue();

				var argNum:Int = next();
				final isRest:Bool = next() == PARAM_REST;

				final args:Array<Dynamic> = [
					while (argNum-- != 0)
					{
						command();
						getValue();
					}
				];

				if (isRest)
				{
					for (i in cast(args.pop(), Array<Dynamic>))
					{
						args.push(i);
					}
				}

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

			case SWITCH:
				command();
				final value:Dynamic = getValue();

				var caseNum:Int = next();
				final endId:Int = next();

				while (caseNum-- != 0)
				{
					var caseValueNum:Int = next();
					final caseValueEndId:Int = next();
					final caseEndId:Int = next();

					while (caseValueNum-- != 0)
					{
						command();

						if (value == getValue())
						{
							this.pos = caseValueEndId;
							command();
							this.pos = endId;
							return linkType;
						}
						else if (caseValueNum == 0)
						{
							this.pos = caseEndId;
						}
					}
				}

				return linkType = NULL;

			case SWITCH_DEFAULT:
				command();
				final value:Dynamic = getValue();

				var caseNum:Int = next();
				final endId:Int = next();

				while (caseNum-- != 0)
				{
					var caseValueNum:Int = next();
					final caseValueEndId:Int = next();
					final caseEndId:Int = next();

					while (caseValueNum-- != 0)
					{
						command();

						if (value == getValue())
						{
							this.pos = caseValueEndId;
							command();
							this.pos = endId;
							return linkType;
						}
						else if (caseValueNum == 0)
						{
							this.pos = caseEndId;
						}
					}
				}

				command();

				return linkType;

			case CONSTRUCTOR:
				final id:Int = next();

				final endPos:Int = next();
				final argNum:Int = next();
				final isRest:Bool = next() == REST;
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
				final isRest:Bool = next() == REST;
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
						while (++i < argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;
					return v;
				}

				var f:Dynamic = if (isRest)
				{
					makeRest(f, argNum);
				}
				else
				{
					#if hl
					Tools.__hl_makeVarArgs(f, argNum);
					#else
					Reflect.makeVarArgs(f);
					#end
				}

				variables[name] = dynamicBuffer[id] = f;
				linkID = id;

				return linkType = DYNAMIC;
			case LOCAL_FUNCTION:
				final id:Int = next();

				final endPos:Int = next();
				final name:String = stringBuffer[next().toInt()];
				final argNum:Int = next();
				final isRest:Bool = next() == REST;
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
						while (++i < argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;

					return v;
				}

				var f:Dynamic = if (isRest)
				{
					makeRest(f, argNum);
				}
				else
				{
					#if hl
					Tools.__hl_makeVarArgs(f, argNum);
					#else
					Reflect.makeVarArgs(f);
					#end
				}

				variables[name] = dynamicBuffer[id] = f;
				linkID = id;

				return linkType = DYNAMIC;
			case ANON_FUNCTION:
				final id:Int = next();
				final endPos:Int = next();
				final argNum:Int = next().toInt();
				final isRest:Bool = next() == REST;
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
						while (++i < argNum);
					}

					command();

					var v:Dynamic = getValue();
					this.pos = lastPos;
					return v;
				}

				var f:Dynamic = if (isRest)
				{
					makeRest(f, argNum);
				}
				else
				{
					#if hl
					Tools.__hl_makeVarArgs(f, argNum);
					#else
					Reflect.makeVarArgs(f);
					#end
				}

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
				throw command.toString() + ' (${command.toInt()}) at pos $pos';
		}
	}

	function makeRest(f:Array<Dynamic>->Dynamic, argNum:Int):Dynamic
	{
		final restId:Int = argNum - 1;
		final f = function(args:Array<Dynamic>)
		{
			return if (args.length > argNum)
			{
				final newArgs:Array<Dynamic> = args.slice(0, restId);
				newArgs.push(args.slice(restId, args.length));

				return f(newArgs);
			}
			else
				f(args);
		};

		return Reflect.makeVarArgs(f);
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

		c ??= ScriptedTypeUtil.resolveScript(cl);
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
