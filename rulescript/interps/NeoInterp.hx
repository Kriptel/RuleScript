package rulescript.interps;

import haxe.Constraints.IMap;
import haxe.Exception;
import hscript.Expr;
import rulescript.RuleScript.IInterp;
import rulescript.Tools.TypePath;
import rulescript.Tools.getScriptProp;
import rulescript.interps.neo.NeoCompiler;
import rulescript.interps.neo.NeoInterpAccess;
import rulescript.interps.neo.NeoTypes;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.IRuleScriptCustomAccessor;
import rulescript.types.Property;
import rulescript.types.ScriptedAbstract;
import rulescript.types.ScriptedEnum;
import rulescript.types.ScriptedType;
import rulescript.types.ScriptedTypeUtil;
import rulescript.types.ScriptedTypedef;

class NeoInterp implements IInterp
{
	public var scriptPackage(default, set):String = '';
	public var scriptName:String;
	public var superInstance(default, set):Dynamic;

	public var hasErrorHandler:Bool;
	public var context:Context;
	public var errorHandler:Exception->Void;

	public var lineInfo:Bool = true;
	public var curLine:Int = 0;

	var isSuperCall(default, null):Bool;

	public var access:RuleScriptAccess;
	public var compiler:NeoCompiler;

	public var variables:Map<String, Dynamic>;

	public var usings:Array<Dynamic>;

	var bytes:Array<NeoByte>;
	var pos:Int = 0;

	var floatBuffer:Array<Float>;
	var stringBuffer:Array<String>;
	var dynamicBuffer:Array<Dynamic>;

	var id:Int = -1;
	var fl:Float = -1;
	var str:String = null;
	var dyn:Dynamic = null;

	public function new()
	{
		access = new NeoInterpAccess(this);
		compiler = new NeoCompiler(this);

		reset();
	}

	public function reset()
	{
		variables = [];
		variables.set('trace', Reflect.makeVarArgs(function(args:Array<Dynamic>)
		{
			haxe.Log.trace(args.join(', '), cast {
				fileName: scriptName ?? "rulescript",
				lineNumber: lineInfo ? curLine : 0
			});

			return;
		}));

		usings = [];

		bytes = [];

		floatBuffer = [];
		stringBuffer = [];
		dynamicBuffer = [];

		scriptPackage = '';
	}

	public function execute(expr:Expr):Dynamic
	{
		compiler.compileExpr(expr);

		return getValue(commandReturn());
	}

	function getValue(type:NeoByte):Dynamic
	{
		return switch (type)
		{
			case INT:
				id;
			case BOOL_TRUE:
				true;
			case BOOL_FALSE:
				false;
			case FLOAT:
				fl;
			case STRING:
				str;
			case NULL, VOID:
				null;
			default:
				dyn;
		}
	}

	function setValue(v:Dynamic):Dynamic
	{
		return dyn = v;
	}

	inline function isTrue(type:NeoByte)
	{
		return getValue(type) == true;
	}

	inline function current():NeoByte
	{
		return bytes[pos];
	}

	inline function next():NeoByte
	{
		return bytes[pos++];
	}

	inline function nextString():String
	{
		return stringBuffer[next()];
	}

	inline function nextBool():Bool
	{
		return next() == BOOL_TRUE;
	}

	inline function skipCommand():NeoByte
	{
		pos = next();
		return VOID;
	}

	inline function commandSkippable():NeoByte
	{
		next();
		return command();
	}

	inline function commandReturn():NeoByte
	{
		return try
		{
			command();
		}
		catch (c:LoopControl)
			switch (c)
			{
				case CReturn(v):
					return v;
				case CContinue:
					throw EInvalidContinue;
				case CBreak:
					throw EInvalidBreak;
			}
	}

	function command():NeoByte
	{
		return switch (next())
		{
			case INTERP_TYPE:
				str = 'NeoInterp';

				STRING;
			case LINE:
				curLine = next();

				command();
			case INT:
				id = next();

				INT;
			case FLOAT:
				fl = floatBuffer[next()];

				FLOAT;
			case STRING:
				str = nextString();

				STRING;

			case NULL:
				NULL;

			case BOOL_TRUE:
				BOOL_TRUE;

			case BOOL_FALSE:
				BOOL_FALSE;

			case IDENT:
				final id:String = nextString();

				dyn = variables[id];

				DYNAMIC;

			case IDENT_LOCAL:
				final id:Int = next();

				dyn = dynamicBuffer[id];

				DYNAMIC;

			case FIELD:
				final obj:Dynamic = getValue(command());
				final f:String = nextString();

				if (obj == null)
					error(EInvalidAccess(f));

				dyn = get(obj, f);

				DYNAMIC;

			case VAR:
				final id:Int = next();

				dynamicBuffer[id] = getValue(command());

				VOID;

			case PROPERTY:
				final name:String = nextString();

				variables[name] = createProperty();

				VOID;

			case PROPERTY_LOCAL:
				final id:Int = next();

				dynamicBuffer[id] = createProperty();

				VOID;

			case BLOCK:
				var v:NeoByte = VOID;

				for (_ in 0...next())
				{
					v = command();
				}

				v;

			case CALL:
				final f:Dynamic = getValue(command());

				if (f == null)
					error(ENullAccess);

				final args:Array<Dynamic> = [
					for (_ in 0...next())
						getValue(command())
				];

				setValue(call(f, args));

				DYNAMIC;

			case IF:
				if (isTrue(command()))
					commandSkippable();
				else
					skipCommand();
			case IF_ELSE:
				var type:NeoByte;

				if (isTrue(command()))
				{
					type = commandSkippable();
					skipCommand();
				}
				else
				{
					skipCommand();
					type = commandSkippable();
				}

				type;
			case OP:
				commandOp(next());
			case ARRAY:
				final obj:Dynamic = getValue(command());
				final index:Dynamic = getValue(command());

				dyn = if (isMap(obj))
					getMapValue(obj, index);
				else
					obj[index];
				DYNAMIC;

			case CREATE_ARRAY:
				final array:Array<Dynamic> = [
					for (_ in 0...next())
						getValue(command())
				];

				dyn = array;

				DYNAMIC;

			case CREATE_MAP:
				final len:Int = next();

				final key:Dynamic = getValue(command());
				final value:Dynamic = getValue(command());

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

				setMapValue(map, key, value);

				for (_ in 0...len)
				{
					setMapValue(map, getValue(command()), getValue(command()));
				}

				dyn = map;

				DYNAMIC;

			case CREATE_OBJECT:
				final obj = {};

				for (_ in 0...next())
				{
					Reflect.setField(obj, nextString(), getValue(command()));
				}

				dyn = obj;

				DYNAMIC;

			case CAST, CHECK_TYPE:
				command();

			case RETURN:
				throw CReturn(command());

			case CONTINUE:
				throw CContinue;

			case BREAK:
				throw CBreak;

			case PACKAGE:
				scriptPackage = nextString();

				VOID;

			case META:
				final name:String = nextString();

				final argsNum:Int = next();

				final args:Null<Array<Dynamic>> = if (argsNum == -1)
					null;
				else
				{
					[
						for (arg in 0...argsNum)
						{
							dynamicBuffer[arg];
						}
					];
				}

				commandMeta(name, args);

			case NEW:
				final cl:String = nextString();
				final args:Array<Dynamic> = [for (_ in 0...next()) getValue(command())];

				dyn = cnew(cl, args);

				DYNAMIC;

			case FOR:
				final vID:Int = next();
				final iterator:Iterator<Dynamic> = makeIterator(getValue(command()));

				final curPos:Int = this.pos;

				for (i in iterator)
				{
					this.pos = curPos;

					dynamicBuffer[vID] = i;
					command();
				}

				VOID;

			case FOR_KEY_VALUE:
				final kID:Int = next();
				final vID:Int = next();
				final iterator:KeyValueIterator<Dynamic, Dynamic> = makeKeyValueIterator(getValue(command()));

				final curPos:Int = this.pos;

				for (key => value in iterator)
				{
					this.pos = curPos;

					dynamicBuffer[kID] = key;
					dynamicBuffer[vID] = value;
					command();
				}

				VOID;

			case WHILE:
				final curPos:Int = this.pos;

				while (getValue(command()))
				{
					commandSkippable();

					this.pos = curPos;
				}

				skipCommand();

				VOID;

			case DO_WHILE:
				final curPos:Int = this.pos;

				do
				{
					this.pos = curPos;

					command();
				}
				while (getValue(command()));

				VOID;
			case SWITCH:
				final switchValue:Dynamic = getValue(command());

				final numCases:Int = next();
				final startPos:Int = pos;

				var matched:Bool = false;
				var type:NeoByte = NULL;

				next();

				for (i in 0...numCases)
				{
					final numValues:Int = next();
					var caseMatch:Bool = false;

					final casePos:Int = pos;
					next();

					for (j in 0...numValues)
					{
						final val:Dynamic = getValue(command());
						if (!caseMatch && switchValue == val)
						{
							caseMatch = matched = true;
							this.pos = casePos;
							skipCommand(); // Skip case values
							break;
						}
					}

					if (caseMatch)
					{
						type = commandSkippable();
						this.pos = startPos;
						skipCommand(); // Skip cases
					}
					else
						skipCommand();
				}

				if (matched)
					skipCommand();
				else
					type = commandSkippable();

				type;

			case TRY:
				final curPos:Int = this.pos;

				try
				{
					var v = commandSkippable();
					skipCommand();
					v;
				}
				catch (e)
				{
					this.pos = curPos;
					skipCommand();
					dynamicBuffer[next()] = e;
					commandSkippable();
				}
			case RS_IMPORT:
				final path:String = nextString(), star:Bool = nextBool();
				final alias:String = nextString(), func:String = nextString();

				if (star)
				{
					for (typeName in Tools.getTypesInPackage(path))
					{
						if (!variables.exists(typeName))
						{
							final type:Dynamic = resolveType(TypePath.createString(path.split('.'), typeName));
							variables.set(typeName, type);
						}
					}
				}
				else
				{
					var name:String = alias ?? func ?? TypePath.getTypeName(path);
					var type:Dynamic = resolveType(path);

					final value = if (func != null)
					{
						get(type, func);
					}
					else
						type;

					variables[name] = value;
				}

				VOID;
			case USING:
				final path:String = nextString();
				final type:Dynamic = resolveType(path);

				if (!usings.contains(type))
					usings.push(type);

				VOID;
			case FUNCTION:
				final funcName:String = nextString();

				final func = makeFunction();

				variables[funcName] = func;

				dyn = func;

				DYNAMIC;

			case ANON_FUNCTION:
				final func = makeFunction();

				dyn = func;

				DYNAMIC;
			case TYPE_VAR_PATH:
				final path:Array<String> = dynamicBuffer[next()];

				dyn = resolveTypeOrValue(path);

				DYNAMIC;
			case id:
				error(EUnknownCommand(id));
		}
	}

	function commandMeta(name:String, args:Array<Dynamic>):NeoByte
	{
		return command();
	}

	function commandOp(op:NeoByte):NeoByte
	{
		return switch (op)
		{
			case OP_PLUS, OP_MINUS, OP_MULT, OP_DIVISION, OP_MODULO, OP_SHIFT_LEFT, OP_SHIFT_RIGHT, OP_UNSIGNED_SHIFT_RIGHT, OP_BIT_AND, OP_BIT_OR,
				OP_BIT_XOR, OP_EQUALS, OP_NOT_EQUALS, OP_LT, OP_LT_EQUAL, OP_GT, OP_GT_EQUAL:
				final a:Dynamic = getValue(command());
				final b:Dynamic = getValue(command());

				setValue(switch (op)
				{
					case OP_PLUS: a + b;
					case OP_MINUS: a - b;
					case OP_MULT: a * b;
					case OP_DIVISION: a / b;
					case OP_MODULO: a % b;
					case OP_SHIFT_LEFT: a << b;
					case OP_SHIFT_RIGHT: a >> b;
					case OP_UNSIGNED_SHIFT_RIGHT: a >>> b;
					case OP_BIT_AND: a & b;
					case OP_BIT_OR: a | b;
					case OP_BIT_XOR: a ^ b;
					case OP_EQUALS: a == b;
					case OP_NOT_EQUALS: a != b;
					case OP_LT: a < b;
					case OP_LT_EQUAL: a <= b;
					case OP_GT: a > b;
					case OP_GT_EQUAL: a >= b;
					default: error(EUnknownCommand(op));
				});

				DYNAMIC;
			case OP_BIT_NEGATION:
				setValue(~getValue(command()));
				DYNAMIC;
			case OP_ARITHMETIC_NEGATION:
				setValue(-getValue(command()));
				DYNAMIC;
			case OP_POST_INCREMENT:
				NULL;
			case OP_POST_DECREMENT:
				NULL;
			// Assign
			case OP_SET:
				final v:String = stringBuffer[next()];

				variables.set(v, getValue(command()));

				DYNAMIC;

			case OP_SET_LOCAL:
				final id:Int = next();

				dynamicBuffer[id] = dyn = getValue(command());

				DYNAMIC;

			case OP_SET_FIELD:
				final obj:Dynamic = getValue(command());
				final field:String = stringBuffer[next()];
				final value:Dynamic = getValue(command());

				dyn = set(obj, field, value);

				DYNAMIC;

			case OP_SET_ARRAY:
				final obj:Dynamic = getValue(command());
				final index:Dynamic = getValue(command());
				final value:Dynamic = getValue(command());

				if (isMap(obj))
					setMapValue(obj, index, value);
				else
					obj[index] = value;

				dyn = value;

				DYNAMIC;

			case OP_NOT: // !
				if (isTrue(command()))
					BOOL_FALSE;
				else
					BOOL_TRUE;
			case OP_AND:
				if (isTrue(command()))
					if (isTrue(commandSkippable()))
					{
						return BOOL_TRUE;
					}

				skipCommand();

				BOOL_FALSE;
			case OP_OR:
				if (isTrue(command()))
				{
					skipCommand();
					return BOOL_TRUE;
				}

				commandSkippable();

			case OP_DYNAMIC:
				NULL;

			case LINE:
				curLine = next();
				command();

			default:
				error(EUnknownCommand(op));
		}
	}

	function call(f:Dynamic, args:Array<Dynamic>):Dynamic
	{
		#if rulescript_use_hl_fixes
		final result:Dynamic = Tools.__hl_callMethod(f, args);
		#else
		final result:Dynamic = Reflect.callMethod(null, f, args);
		#end

		return result;
	}

	function get(o:Dynamic, f:String):Dynamic
	{
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

		if (o == this)
		{
			if (variables.exists(f))
				return getScriptProp(variables.get(f));
			else
				o = superInstance;
		}

		if (o is IRuleScriptCustomAccessor)
			return cast(o, IRuleScriptCustomAccessor).getField(f);

		if (o is ScriptedType)
		{
			switch (cast(o, ScriptedType).__rulescript_type)
			{
				case CLASS, ABSTRACT:
					var cl:RuleScriptedClass = cast(o, RuleScriptedClass);
					if (cl.variableExists(f))
						return getScriptProp(cl.getVariable(f));
				case ENUM:
					var en:ScriptedEnum = cast(o, ScriptedEnum);

					return en.getEnumConstructor(f);
				default:
			}
		}

		var prop:Dynamic = Reflect.getProperty(o, f);

		if (prop != null)
			return getScriptProp(prop);

		if (usings.length > 0)
		{
			for (cl in usings)
			{
				var prop:Dynamic = Reflect.getProperty(cl, f);
				if (prop != null)
					return Tools.usingFunction.bind(o, prop, _, _, _, _, _, _, _, _);
			}
		}

		return null;
	}

	function set(obj:Dynamic, field:String, value:Dynamic):Dynamic
	{
		if (obj == null)
			error(EInvalidAccess(field));

		if (obj == this)
		{
			if (variables.exists(field))
			{
				var variable:Dynamic = variables.get(field);
				variable is Property ? cast(variable, Property).value = value : variables.set(field, value);
				return value;
			}
			else
				obj = superInstance;
		}

		if (obj is IRuleScriptCustomAccessor)
			return cast(obj, IRuleScriptCustomAccessor).setField(field, value);

		if (obj is RuleScriptedClass)
		{
			var cl:RuleScriptedClass = cast(obj, RuleScriptedClass);
			if (cl.variableExists(field))
			{
				var o = cl.getVariable(field);
				return o is Property ? cast(o, Property).value = value : cl.setVariable(field, value);
			}
		}

		Reflect.setProperty(obj, field, value);

		return value;
	}

	function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
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
					return cast(c, ScriptedAbstract).createInstance(args);
				default:
			}

		#if rulescript_use_hl_fixes
		return Reflect.isFunction(c) ? Tools.__hl_callMethod(c, args) : Tools.isClass(c) ? Tools.__hl_createInstance(c, args) : c;
		#else
		return Reflect.isFunction(c) ? Reflect.callMethod(null, c, args) : Tools.isClass(c) ? Type.createInstance(c, args) : c;
		#end
	}

	function error(e:NeoError):Dynamic
	{
		throw {e: e, line: curLine};
	}

	function resolve(id:String):Dynamic
	{
		if (variables.exists(id))
			return variables[id];
		var v:Dynamic = null;
		if (superInstance != null)
			v = Reflect.getProperty(superInstance, id);
		return v ?? error(EUnknownVariable(id));
	}

	function isMap(obj:Dynamic):Bool
	{
		return obj is IMap;
	}

	function getMapValue(obj:Dynamic, key:Dynamic):Dynamic
	{
		return cast(obj, IMap<Dynamic, Dynamic>).get(key);
	}

	function setMapValue(obj:Dynamic, key:Dynamic, value:Dynamic):Void
	{
		cast(obj, IMap<Dynamic, Dynamic>).set(key, value);
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

	function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic>
	{
		#if hl
		if (v is haxe.ds.StringMap)
			return new haxe.iterators.MapKeyValueIterator(v);
		#end

		#if js
		// don't use try/catch (very slow)
		if (v is Array)
			return (v : Array<Dynamic>).keyValueIterator();
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();
		#else
		try
			v = v.keyValueIterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}

	var typePaths:Map<String, Dynamic> = [];

	function resolveTypeOrValue(path:Array<String>):Dynamic
	{
		final id:String = path[0];

		if ((!variables.exists(id))
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

		var obj:Dynamic = resolve(id);

		var currentField:Int = 0;
		while (path[++currentField] != null)
			obj = get(obj, path[currentField]);

		return obj;
	}

	function createProperty()
	{
		final getF:PropertyAccess = switch (next())
		{
			case PROP_DEFAULT: DEFAULT;
			case PROP_CALLBACK: GET(getValue(command()));
			case PROP_NULL: NULL;
			case PROP_DYNAMIC: DYNAMIC(getValue(command()));
			case PROP_NEVER: NEVER;
			default: null;
		}

		final setF:PropertyAccess = switch (next())
		{
			case PROP_DEFAULT: DEFAULT;
			case PROP_CALLBACK: SET(cast getValue(command()));
			case PROP_NULL: NULL;
			case PROP_DYNAMIC: DYNAMIC(getValue(command()));
			case PROP_NEVER: NEVER;
			default: null;
		}

		final prop = new Property(getF, setF);
		prop._lazyValue = cast getValue(command());
		return prop;
	}

	function makeFunction():Dynamic
	{
		final argsNum:Int = next();
		final minArgs:Int = next();

		final isRest:Bool = nextBool();

		final pos:Int = this.pos + 1; // The skip command is not needed here.

		skipCommand();

		final endPos:Int = this.pos;

		final func:Dynamic = function(args:Array<Dynamic>)
		{
			final lastPos:Int = this.pos;

			this.pos = pos;

			if (args == null)
				args = [];

			if (args.length < minArgs)
			{
				error(MissingRequiredArgument(args.length, minArgs));
			}

			for (i in 0...argsNum + 1)
			{
				var argValue = (i < args.length) ? args[i] : null;
				dynamicBuffer[next()] = argValue;
			}

			final type = command();

			this.pos = lastPos;

			return getValue(type);
		}

		return if (isRest)
		{
			Tools.makeRestFunction(func, argsNum);
		}
		else
		{
			#if rulescript_use_hl_fixes
			Tools.__hl_makeVarArgs(func, argsNum);
			#else
			Reflect.makeVarArgs(func);
			#end
		}
	}

	function resolveType(path:String)
	{
		if (context != null)
			return context.resolveType(path)
		else
			return Tools.resolveType(path);
	}

	@:noCompletion
	var superFields:Array<String> = [];

	private function set_superInstance(value:Dynamic):Dynamic
	{
		if (value != null)
		{
			var o:Class<Dynamic> = Tools.isClass(value) ? cast value : Type.getClass(value);
			superFields = (o != null) ? Type.getInstanceFields(o) : [];
		}
		return superInstance = value;
	}

	private function set_errorHandler(value:haxe.Exception->Void):haxe.Exception->Void
	{
		return errorHandler = value;
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
