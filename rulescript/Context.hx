package rulescript;

import rulescript.interps.IInterp;
import rulescript.interps.RuleScriptInterp;
import rulescript.parsers.HxParser;
import rulescript.parsers.IParser;

class Context
{
	public static var defaultDefines:Map<String, String> = rulescript.internal.macros.DefineMacro.get();

	public var defines:Map<String, String>;

	public function new()
	{
		defines = defaultDefines.copy();
	}

	@:allow(rulescript.RuleScript.new)
	function initializeScript(script:RuleScript, parser:IParser, interp:IInterp)
	{
		script.parser ??= createParser();
		script.interp ??= createInterp();
	}

	function createParser():IParser
	{
		return new HxParser(this);
	}

	function createInterp():IInterp
	{
		return new RuleScriptInterp();
	}
}
