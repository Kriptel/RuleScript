package rulescript;

import haxe.extern.EitherType;
import hscript.Expr;
import rulescript.parsers.*;

/**
 * ## Adding script:
 *
 * ```haxe
 * script = new RuleScript(new HxParser());
 *
 * // Get parser as HxParser
 * script.getParser(HxParser).allowAll();
 *
 * // Run execute inside try-catch
 * script.tryExecute('trace("Hello World");'); // Hello World
 *
 * script.execute('1+1;'); // 2
 * ```
 *
 * ## Example:
 *
 * Package
 * ```haxe
 * package scripts.hello.world;
 * ```
 * ### Import class:
 * ```haxe
 * import haxe.ds.StringMap;
 *
 * var map = new StringMap();
 * map.set("Hello","World");
 * trace(map.get("Hello")); // World
 * ```
 *
 * ### Import with alias:
 *
 * ```haxe
 * import haxe.ds.StringMap as StrMap;
 *
 * var map = new StrMap();
 * map.set("Hello","World");
 * trace(map.get("Hello")); // World
 * ```
 *
 * You also can use `in` keyword
 * ```haxe
 * import haxe.ds.StringMap in StrMap;
 *
 * var map = new StrMap();
 * map.set("Hello","World");
 * trace(map.get("Hello")); // World
 * ```
 *
 * ### Using:
 * ```haxe
 * using Reflect;
 *
 * var a = {
 *  "Hello":"World"
 * };
 * trace(a.getProperty("Hello")); // World
 * ```
 *
 * ### String interpolation
 * ```haxe
 * var a = 'Hello';
 * return 'RuleScript: $a World'; // RuleScript: Hello World
 * ```
 *
 */
class RuleScript
{
	/**
	 * Edit, if you want make importable script
	 * @see [dynamic keyword](https://haxe.org/manual/class-field-dynamic.html)
	 */
	public static dynamic function resolveScript(name:String):Dynamic
	{
		return null;
	}

	public static dynamic function createInterp():IInterp
	{
		return new RuleScriptInterp();
	}

	/**
	 * Package => Imports
	 */
	public static var defaultImports:Map<String, Map<String, Dynamic>> = [
		'' => [
			#if hl
			'Std' => rulescript.std.hl.Std, 'Math' => rulescript.std.hl.Math,
			#else
			'Std' => Std, 'Math' => Math,
			#end
			'Type' => Type,
			'Reflect' => Reflect,
			'StringTools' => StringTools,
			'Date' => Date,
			'DateTools' => DateTools,
			'Xml' => Xml,
			#if sys 'Sys' => Sys #end
		]
	];

	public var interp(default, set):IInterp;

	public var access:RuleScriptAccess;

	public var scriptName(get, set):String;

	public var scriptPackage(get, set):String;

	public var superInstance(get, set):Dynamic;

	public var variables(get, set):Map<String, Dynamic>;

	public var parser:Parser;

	public var hasErrorHandler(get, set):Bool;

	public var errorHandler(get, set):haxe.Exception->Void;

	public function new(?interp:IInterp, ?parser:Parser)
	{
		// You can register custom parser in a child class
		this.interp ??= interp ?? createInterp();
		this.parser ??= parser ?? new HxParser();
	}

	public function execute(code:EitherType<String, Expr>):Dynamic
	{
		return access.execute(code is String ? parser.parse(cast code) : cast code);
	}

	public function tryExecute(code:EitherType<String, Expr>, ?customCatch:haxe.Exception->Dynamic):Dynamic
	{
		return try
		{
			execute(code);
		}
		catch (v)
			customCatch != null ? customCatch(v) : v.details();
	}

	public function getParser<T:Parser>(?parserClass:Class<T>):T
	{
		return cast parser;
	}

	public function getInterp<T>(?interpClass:Class<T>):T
	{
		return cast interp;
	}

	function set_interp(v:IInterp):IInterp
	{
		access = v.access;
		return interp = v;
	}

	function get_scriptName():String
	{
		return access.scriptName;
	}

	function set_scriptName(v:String):String
	{
		return access.scriptName = v;
	}

	function get_scriptPackage():String
	{
		return access.scriptPackage;
	}

	function set_scriptPackage(v:String):String
	{
		return access.scriptPackage = v;
	}

	function get_superInstance():Dynamic
	{
		return access.superInstance;
	}

	function set_superInstance(v:Dynamic):Dynamic
	{
		return access.superInstance = v;
	}

	function get_variables():Map<String, Dynamic>
	{
		return access.getVariables();
	}

	function set_variables(v:Map<String, Dynamic>):Map<String, Dynamic>
	{
		return access.setVariables(v);
	}

	function get_hasErrorHandler():Bool
	{
		return access.hasErrorHandler;
	}

	function set_hasErrorHandler(v:Bool):Bool
	{
		return access.hasErrorHandler = v;
	}

	function get_errorHandler():haxe.Exception->Void
	{
		return access.errorHandler;
	}

	function set_errorHandler(v:haxe.Exception->Void):haxe.Exception->Void
	{
		return access.errorHandler = v;
	}
}

interface IInterp
{
	var access:RuleScriptAccess;
}
