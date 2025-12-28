package rulescript;

import rulescript.types.ScriptedAbstract;
import rulescript.types.ScriptedType;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.context.EVariableModifiers;
import rulescript.types.context.EVariableDeclarations;

/**
 * The Context stores types to preserve repeated imports, 
 * eliminating the need to compile script types or search for native ones.
 * 
 * All script types automatically inherit the Context.
 */
class Context {
	public var types:Map<String, Dynamic> = [];
	public var variables:Map<String, ContextVariable> = [];

	@:deprecated public var publicVariables(default, never):Map<String, Dynamic> = [];
	@:deprecated public var staticVariables(default, never):Map<String, Dynamic> = [];

	public function new() {}

	public function reset():Void {
		types = [];

		resetVariables();
	}

	public function resetVariables():Void {
		variables = []; // yuhuh -orbl
	}

	public function resolveType(path:String):Dynamic {
		if (types.exists(path))
			return types[path];
		else {
			final t:Dynamic = Tools.resolveType(path, this);

			if (t is ScriptedType)
				switch (cast(t, ScriptedType).__rulescript_type) {
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

typedef ContextVariable = {modifier:EVariableModifiers, declaration:EVariableDeclarations, value:Dynamic, ?parent:String};
