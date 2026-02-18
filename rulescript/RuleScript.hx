package rulescript;

import haxe.extern.EitherType;
import hscript.Expr;
import rulescript.interps.RuleScriptInterp;
import rulescript.parsers.HxParser;
import rulescript.parsers.Parser;
import rulescript.scriptedClass.RuleScriptedClass;
import rulescript.types.ScriptedTypeUtil;

#if (hscript < "2.6.0")
#error "Error: HScript version is outdated. RuleScript requires version 2.6.0 or higher."
#end
#if (rulescript_use_hl_fixes && !hl)
#error "Error: The flag 'rulescript_use_hl_fixes' can only be used when targeting HashLink"
#end

/**
 * This class serves as a wrapper/container(?) for executing code and managing the interpreter, 
 * parser, script context, variables, super instances, and error handling. 💛
 * 
 * **This isn't required for RuleScript to work, so you can either use this or create your own...**
 * 
 * This class provides functions for:
 * - Executing code (`execute`, `tryExecute`)
 * - Creating scripted instances (`createScriptedInstance`)
 * - Accessing the parser / interp. (`getInterp` / `getParser`)
 * - Changing Interp, Parser, or Access. (check the constructor (`new`) for a reference)
 * - Managing default imports. (`defaultImports`) `STATIC`
 * 
 * **NOTICE: Default imports are stored as a static variable. Access them via `RuleScript.defaultImports`.**
 * 
 * **This class is designed to be extendable, allowing you to use your own parser, interp or context...**
 * 
 * @see https://github.com/kriptel/rulescript/tree/dev/docs/the-basics.md
 */
class RuleScript
{
	// i'm not documenting deprecated variables/methods... -orbl
	@:deprecated('`resolveScript` is deprecated, use `ScriptedTypeUtil.resolveScript`')
	public static var resolveScript(get, set):String->Dynamic;

	static function get_resolveScript():String->Dynamic
	{
		return ScriptedTypeUtil.resolveScript;
	}

	static function set_resolveScript(v:String->Dynamic):String->Dynamic
	{
		return ScriptedTypeUtil.resolveScript = v;
	}

	/**
	 * This dynamic method is internally used to create an interp.
	 * To change the default interp, you'll need to override this method. 
	 * 
	 * **Make sure the interp you override it with has implemented `IInterp`**
	 * 
	 * @return IInterp
	 */
	public static dynamic function createInterp():IInterp
	{
		return new RuleScriptInterp();
	}

	/**
	 * Resolves a scripted class by it's type path and returns an `Access` instance.
	 * 
	 * @param typePath The string path of the type to resolve.
	 * @param context (Optional) The context used for type resolution. If null, a default resolver is used.
	 * @return Access
	 */
	public static function resolveScriptedClass(typePath:String, ?context:Context):Access
	{
		final cl:Dynamic = context != null ? context.resolveType(typePath) : Tools.resolveType(typePath);

		if (cl is RuleScriptedClass)
		{
			return cast new Access(cl);
		}

		return null;
	}

	/**
	 * Create an scripted instance, by either using a type or a path.
	 * 
	 * @param typeOrPath Either a `ScriptedClass` or a path.
	 * @param args (Optional) Constructor arguments. 
	 * @param context (Optional) Use an already created context.
	 * @return Null<Access>
	 */
	public static function createScriptedInstance(typeOrPath:EitherType<String, ScriptedClass>, ?args:Array<Dynamic>, ?context:Context):Null<Access>
	{
		if (typeOrPath is String)
			return resolveScriptedClass(typeOrPath, context).createInstance(args);

		return cast(typeOrPath, ScriptedClass).createInstance(args);
	}

	/**
	 * Default imports, everything here will be automatically added to the variables when creating a new script.
	 * This functions similarly to `import.hx`.
	 * 
	 * Structure: Package => Types.
	 * 
	 * @see https://haxe.org/manual/type-system-import-defaults.html/
	 */
	public static var defaultImports:Map<String, Map<String, Dynamic>> = [
		'' => [
			#if hl
			'Std' => rulescript.std.hl.Std, 'Math' => rulescript.std.hl.Math, 'Reflect' => rulescript.std.hl.Reflect,
			#else
			'Reflect' => Reflect, 'Std' => Std, 'Math' => Math,
			#end
			#if sys 'Sys' => Sys, #end
			'Type' => Type,
			'StringTools' => StringTools,
			'Date' => Date,
			'DateTools' => DateTools,
			'Xml' => Xml,
			'Int' => Int,
			'String' => String,
			'Float' => Float,
			'Bool' => Bool
		]
	];

	/**
	 * The interpreter.
	 */
	public var interp(default, set):IInterp;

	/**
	 * The access.
	 */
	public var access:RuleScriptAccess;

	/** 
	 * The script name.
	 * 
	 * This value is automatically set when using a scripted class.
	 * Otherwise, it remains unchanged unless you modify it manually.
	 */
	public var scriptName(get, set):String;

	/**
	 * The script package.
	 * 
	 * This value is usually whatever you set the package to inside of the script.
	 * 
	 * For example: 
	 * ```haxe
	 * package rule.script; // `scriptPackage` will return "rule.script".
	 * ```
	 */
	public var scriptPackage(get, set):String;

	/**
	 * The super instance.
	 * 
	 * This is whatever you want the script to be able to access.
	 * 
	 * For example:
	 * ```haxe
	 * // lets say you have a variable in the class instance like.
	 * public var name:Array<String> = ["kriptel", "orbl"]; // class instance
	 * 
	 * /////////////////////////////////////////////////////////////////////////
	 * 
	 * // you'll be able to access that variable inside the script.
	 * trace(name); // Returns: [kriptel, orbl]; || script.
	 * 
	 * ```
	 */
	public var superInstance(get, set):Dynamic;

	/**
	 * The script variables.
	 * 
	 * ```haxe
	 * variables.set('name', 'orbl'); // source
	 * 
	 * ///////////////////////////////////////////
	 * 
	 * trace(name); // returns: "orbl" || script
	 */
	public var variables(get, set):Map<String, Dynamic>;

	/**
	 * The parser.
	 */
	public var parser:Parser;

	/**
	 * This variable indicates whether an error handler has been set.
	 * Its recommended to check this before trying to call the `errorHandler` method...
	 */
	public var hasErrorHandler(get, set):Bool;

	/**
	 * Error handler
	 */
	public var errorHandler(get, set):haxe.Exception->Void;

	/**
	 * The script context handles repeated imports, and public / static variables.
	 */
	public var context(get, set):Context;

	// i wonder what this is...
	public function new(?interp:IInterp, ?parser:Parser, ?context:Context)
	{
		// You can register custom parser in a child class
		this.interp ??= interp ?? createInterp();
		this.parser ??= parser ?? new HxParser();

		if (context != null)
			this.context = context;
	}

	/**
	 * This method allows you to either execute a `Expr` or a string.
	 * pretty self explanatory...
	 * 
	 * @param code Either a `Expr` or a `String`.
	 * @return Dynamic Whether gets returned after executing...
	 */
	public function execute(code:EitherType<String, Expr>):Dynamic
	{
		return access.execute(code is String ? parser.parse(cast code) : cast code);
	}

	/**
	 * Tries to execute the given code and optionally handles exceptions with a custom catch.
	 * 
	 * @param code Either a string or a `Expr`.
	 * @param customCatch (Optional) Exception catch error.
	 * @return It returns either the result of the execution or information about the error.
	 */
	public function tryExecute(code:EitherType<String, Expr>, ?customCatch:haxe.Exception->Dynamic):Dynamic
	{
		return try
		{
			execute(code);
		}
		catch (v)
			customCatch != null ? customCatch(v) : v.details();
	}

	/**
	 * Returns the current parser instance, optionally cast to a specific parser class.
	 * 
	 * @param parserClass (Optional) Parser class type.
	 * @return The parser instance.
	 */
	public function getParser<T:Parser>(?parserClass:Class<T>):T
	{
		return cast parser;
	}

	/**
	 * Returns the current interpreter instance.
	 * 
	 * @param interpClass (Optional) Interpreter class type.
	 * @return The interpreter instance.
	 */
	public function getInterp<T:IInterp>(?interpClass:Class<T>):T
	{
		return cast interp;
	}

	////////////////////////////////////////////////////////////////////

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

	function get_context():Dynamic
	{
		return access.context;
	}

	function set_context(v:Dynamic):Dynamic
	{
		return access.context = v;
	}
}

interface IInterp
{
	var access:RuleScriptAccess;
}
