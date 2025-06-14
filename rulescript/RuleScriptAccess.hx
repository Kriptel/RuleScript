package rulescript;

import hscript.Expr;

/**
 * Implements a single API for all interpreters.
 */
@:allow(rulescript.RuleScript)
class RuleScriptAccess
{
	/**
	 * Returns interp globals.
	 */
	public function getVariables():Map<String, Dynamic>
	{
		return null;
	}

	/**
	 * Sets interpreter globals
	 */
	public function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return null;
	}

	/**
	 * Returns `true` if variable with identifier `name` exists.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	public function variableExists(name:String):Bool
	{
		return false;
	}

	/**
	 * Returns variable with identifier `name`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	public function getVariable(name:String):Dynamic
	{
		return null;
	}

	/**
	 * Sets variables `name` key to `value`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return null;
	}

	/**
	 * Removes variable `name`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	public function removeVariable(name:String):Bool
	{
		return false;
	}

	/**
	 * Calls function `name` with arguments `args`
	 * 
	 * if function `name` is null, returns null.
	 * 
	 * if `name` or `args` are null, the result is unspecified.
	 */
	public function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		return null;
	}

	/**
	 * Calls function `name` with arguments `args`
	 * 
	 * if function `name`, `name` or `args` are null, the result is unspecified.
	 */
	public function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic
	{
		return null;
	}

	public function execute(expr:Expr):Dynamic
	{
		return null;
	}

	// Backend
	var scriptName(get, set):String;
	var scriptPackage(get, set):String;

	var superInstance(get, set):Dynamic;

	var hasErrorHandler(get, set):Bool;

	var errorHandler(get, set):haxe.Exception->Void;

	function get_scriptName():String
	{
		return null;
	}

	function set_scriptName(v:String):String
	{
		return null;
	}

	function get_scriptPackage():String
	{
		return null;
	}

	function set_scriptPackage(v:String):String
	{
		return null;
	}

	function get_superInstance():Dynamic
	{
		return null;
	}

	function set_superInstance(v:Dynamic):Dynamic
	{
		return null;
	}

	function get_hasErrorHandler():Bool
	{
		return false;
	}

	function set_hasErrorHandler(v:Bool):Bool
	{
		return false;
	}

	function get_errorHandler():haxe.Exception->Void
	{
		return null;
	}

	function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
	{
		return null;
	}

	@:noCompletion public var isSuperCall(get, never):Bool;

	function get_isSuperCall():Bool
	{
		return false;
	}

	@:noCompletion public var hasConstructor(get, never):Bool;

	function get_hasConstructor():Bool
	{
		return false;
	}

	@:noCompletion public function createConstructor(args:Array<Dynamic>):ConstructorAccess
	{
		return null;
	}
}

typedef ConstructorAccess =
{
	pre:() -> Void,
	getSuperArgs:() -> Array<Dynamic>,
	post:() -> Void
}
