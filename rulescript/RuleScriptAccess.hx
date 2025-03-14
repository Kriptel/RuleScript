package rulescript;

@:allow(rulescript.RuleScript)
class RuleScriptAccess
{
	private var _rulescript:RuleScript;

	private function new(rulescript:RuleScript)
	{
		_rulescript = rulescript;
	}

	public function getVariables():Map<String, Dynamic>
	{
		return _rulescript.interp.variables;
	}

	public function variableExists(name:String):Bool
	{
		return _rulescript.interp.variables.exists(name);
	}

	public function getVariable(name:String):Dynamic
	{
		return _rulescript.interp.variables.get(name);
	}

	public function setVariable(name:String, value:Dynamic):Dynamic
	{
		return _rulescript.interp.variables[name] = value;
	}

	public function callFunction(name:String, args:Array<Dynamic>):Null<Any>
	{
		if (!variableExists(name))
		{
			return null;
		}
		return Reflect.callMethod({}, getVariable(name), args);
	}
}