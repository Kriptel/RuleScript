package rulescript.types;

import hscript.Expr;
import rulescript.types.ScriptedType.TypeID;

class ScriptedTypedef implements ScriptedType
{
	public var impl:Expr;

	public function new(impl:Expr)
	{
		this.impl = impl;
	}

	var _value:Dynamic = null;

	public function resolve(execute:Expr->Dynamic):Dynamic
	{
		return _value ??= execute(impl);
	}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	function get___rulescript_type():TypeID
	{
		return TYPEDEF;
	}
}
