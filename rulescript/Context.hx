package rulescript;

import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.ScriptedAbstract;
import rulescript.types.ScriptedType;

/**
 * The Context stores types to preserve repeated imports, 
 * eliminating the need to compile script types or search for native ones.
 * 
 * All script types automatically inherit the Context.
 */
class Context
{
	public var types:Map<String, Dynamic> = [];

	public function new() {}

	public function resolveType(path:String):Dynamic
	{
		if (types.exists(path))
			return types[path];
		else
		{
			final t:Dynamic = Tools.resolveType(path);

			if (t is ScriptedType)
				switch (cast(t, ScriptedType).__rulescript_type)
				{
					case CLASS:
						@:privateAccess cast(t, ScriptedClass).interp.access.context = this;
					case ABSTRACT:
						@:privateAccess cast(t, ScriptedAbstract).__impl.interp.access.context = this;
					default:
				}

			return types[path] = t;
		};
	}
}
