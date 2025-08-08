package rulescript;

/**
 * Provides custom property access for RuleScript.
 * @param `_rget` is called when **getting** a property.
 * @param `_rset` is called when **setting** a property.
 */
interface IRuleScriptCustomAccessor {
	public function _rset(id:String, value:Dynamic):Dynamic;
	public function _rget(id:String):Dynamic;
}
