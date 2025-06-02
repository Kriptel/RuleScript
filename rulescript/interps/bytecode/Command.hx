package rulescript.interps.bytecode;

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
	var LINE = 8;

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
	var SWITCH = 30;
	var SWITCH_DEFAULT = 31;
	var TRY = 32;

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

	// PROPERTY
	var CREATE_PROPERTY = 65;
	var PROP_DEFAULT = 66;
	var PROP_CALLBACK = 67;
	var PROP_DYNAMIC = 68;
	var PROP_NULL = 69;
	var PROP_NEVER = 70;

	// OTHER FEATURES
	var CAST_INT_TO_FLOAT = 80;
	var CREATE_OBJECT = 81;
	var BOOL_TRUE = 82;
	var BOOL_FALSE = 83;
	var BUFFER_LINK = 84;
	var ARRAY_GET = 85;
	var ARRAY_SET = 86;
	var MAP_GET = 87;
	var MAP_SET = 88;
	var OBJECT_SET = 89;
	var OBJECT_SET_PROP = 90;
	var INT_ITERATOR = 91;
	var REST = 92;
	var PARAM = 93;
	var PARAM_REST = 94;

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
