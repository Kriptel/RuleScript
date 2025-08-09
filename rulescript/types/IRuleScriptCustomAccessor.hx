package rulescript.types;

/**
 * Provides custom property access for RuleScript.
 * @param `getField` is called when **getting** a property.
 * @param `setField` is called when **setting** a property.
 */
interface IRuleScriptCustomAccessor
{
	public function setField(id:String, value:Dynamic):Dynamic;
	public function getField(id:String):Dynamic;
}
