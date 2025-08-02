package rulescript.interps.neo;

import hscript.Expr;

enum abstract NeoType(Int) from Int to Int
{
	var DYNAMIC;
}

enum abstract NeoByte(Int) from Int to Int
{
	// TYPES
	var INT;
	var FLOAT;
	var STRING;
	var DYNAMIC;
	var BOOL;
	var VOID;

	// COMMANDS
	var LINE;
	var IDENT;
	var IDENT_LOCAL;
	var VAR;
	var BLOCK;
	var FIELD;
	var BINOP;
	var UNOP;
	var CALL;
	var CALL_USING;
	var IF;
	var IF_ELSE;
	var WHILE;
	var FOR;
	var FOR_KEY_VALUE;
	var BREAK;
	var CONTINUE;
	var FUNCTION;
	var RETURN;
	var RETURN_VOID;
	var ARRAY;
	var CREATE_ARRAY;
	var CREATE_MAP;
	var NEW;
	var THROW;
	var TRY;
	var CREATE_OBJECT;
	var TERNARY;
	var SWITCH;
	var DO_WHILE;
	var META;
	var CHECK_TYPE;
	var CAST;

	// VALUES
	var NULL;
	var INTERP_TYPE;
	var BOOL_TRUE;
	var BOOL_FALSE;

	// OPS
	var OP;

	var OP_PLUS;
	var OP_MINUS;
	var OP_MULT;
	var OP_DIVISION;

	var OP_MODULO;

	var OP_SHIFT_LEFT;
	var OP_SHIFT_RIGHT;
	var OP_UNSIGNED_SHIFT_RIGHT;
	var OP_BIT_AND;
	var OP_BIT_OR;
	var OP_BIT_XOR;

	var OP_BIT_NEGATION;

	var OP_ARITHMETIC_NEGATION;

	var OP_POST_INCREMENT;
	var OP_POST_DECREMENT;

	var OP_SET;
	var OP_SET_LOCAL;
	var OP_SET_FIELD;
	var OP_SET_ARRAY;

	var OP_NOT;

	var OP_DYNAMIC;
}

enum NeoError
{
	EUnknownCommand(cmd:NeoByte);
	EUnknownVariable(id:String);
	EUnsupportedExpr(e:Expr);
	EInvalidOperator(op:String);
	EInvalidIterator(v:Dynamic);
	EInvalidMap(e:String);
	EInvalidContinue;
	EInvalidBreak;
}

enum LoopControl
{
	CReturn(v:Dynamic);
	CContinue;
	CBreak;
}
