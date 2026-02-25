package rulescript;

import haxe.exceptions.NotImplementedException;
import hscript.Expr;
import rulescript.scriptedClass.ScriptedConstructor;

/**
 * Implements a single API for all interpreters.
 */
@:allow(rulescript.RuleScript)
abstract class RuleScriptAccess
{
	/**
	 * Returns interp globals.
	 */
	abstract public function getVariables():Map<String, Dynamic>;

	/**
	 * Sets interpreter globals
	 */
	abstract public function setVariables(newVariables:Map<String, Dynamic>):Map<String, Dynamic>;

	/**
	 * Resets the interp.
	 */
	abstract public function resetInterp():Void;

	/**
	 * Returns `true` if variable with identifier `name` exists.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	abstract public function variableExists(name:String):Bool;

	/**
	 * Returns variable with identifier `name`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	abstract public function getVariable(name:String):Dynamic;

	/**
	 * Sets variables `name` key to `value`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	abstract public function setVariable(name:String, value:Dynamic):Dynamic;

	/**
	 * Removes variable `name`.
	 * 
	 * if `name` is null, the result is unspecified.
	 */
	abstract public function removeVariable(name:String):Bool;

	/**
	 * Calls function `name` with arguments `args`
	 * 
	 * if function `name` is null, returns null.
	 * 
	 * if `name` or `args` are null, the result is unspecified.
	 */
	abstract public function callFunction(name:String, args:Array<Dynamic>):Dynamic;

	/**
	 * Calls function `name` with arguments `args`
	 * 
	 * if function `name`, `name` or `args` are null, the result is unspecified.
	 */
	abstract public function callFunctionUnsafe(name:String, args:Array<Dynamic>):Dynamic;

	abstract public function execute(expr:Expr):Dynamic;

	abstract public function posInfos():haxe.PosInfos;

	// Backend
	var scriptName(get, set):String;
	var scriptPackage(get, set):String;

	var superInstance(get, set):Dynamic;

	var hasErrorHandler(get, set):Bool;

	var errorHandler(get, set):haxe.Exception->Void;

	var context(get, set):Context;

	abstract function get_scriptName():String;

	abstract function set_scriptName(v:String):String;

	abstract function get_scriptPackage():String;

	abstract function set_scriptPackage(v:String):String;

	abstract function get_superInstance():Dynamic;

	abstract function set_superInstance(v:Dynamic):Dynamic;

	abstract function get_hasErrorHandler():Bool;

	abstract function set_hasErrorHandler(v:Bool):Bool;

	abstract function get_errorHandler():haxe.Exception->Void;

	abstract function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void;

	abstract function get_context():Context;

	abstract function set_context(v:Context):Context;

	@:noCompletion public var isSuperCall(get, set):Bool;

	abstract function get_isSuperCall():Bool;

	abstract function set_isSuperCall(v:Bool):Bool;

	@:noCompletion public var hasConstructor(get, never):Bool;

	function get_hasConstructor():Bool
	{
		throw NotImplementedException;
	}

	@:noCompletion public function createConstructor(args:Array<Dynamic>):ScriptedConstructor
	{
		throw NotImplementedException;
	}

	@:noCompletion private function __resolve(path:String):Dynamic
	{
		return null;
	}

	@:noCompletion private function __resolveType(path:String):Dynamic
	{
		return null;
	}
}
