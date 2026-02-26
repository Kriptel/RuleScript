package rulescript.types;

import rulescript.Tools.EnumPattern;
import rulescript.Tools.ImportPath;
import rulescript.types.ScriptedType.TypeID;
import rulescript.types.decl.EnumDecl;

abstract EnumConstructor(Dynamic)
{
	public function new(en:ScriptedEnum, decl:EnumField)
	{
		this = switch (decl.type)
		{
			case null:
				new ScriptedEnumInstance(en, decl, null);
			case KFunction(f) if (f.args.length > 0):
				Reflect.makeVarArgs(ScriptedEnumInstance.new.bind(en, decl));
			default: throw 'Invalid enum constructor';
		}
	}
}

class ScriptedEnum implements ScriptedType
{
	public var module:ScriptedModule;

	public var impl:EnumDecl;

	public var constructors:Map<String, EnumConstructor>;
	public var constructorNames:Array<String> = [];

	public function new(impl:EnumDecl, module:ScriptedModule)
	{
		this.impl = impl;
		this.module = module;

		constructors = [];

		for (c in impl.constructs)
		{
			constructorNames[c.index] = c.name;
			constructors.set(c.name, new EnumConstructor(this, c));
		}
	}

	public function createEnumInstance() {}

	@:noCompletion public var __rulescript_type(get, never):TypeID;

	function get___rulescript_type():TypeID
	{
		return ENUM;
	}

	public function hasEnumConstructor(c:String):Bool
	{
		return constructors.exists(c);
	}

	public function getEnumConstructor(c:String):EnumConstructor
	{
		return constructors[c];
	}

	public function getEnumConstructorIndex(c:String):Int
	{
		return constructorNames.indexOf(c);
	}

	public function enumHasParams(c:String):Bool
	{
		return !(getEnumConstructor(c) is ScriptedEnumInstance);
	}

	public function toString():String
	{
		return ImportPath.createString(module.pack.split('.'), module.name, impl.name);
	}
}

class ScriptedEnumInstance
{
	public var en:ScriptedEnum;
	public var impl:EnumField;
	public var params:Array<Dynamic>;

	public function new(en:ScriptedEnum, impl:EnumField, params:Array<Dynamic>)
	{
		this.en = en;
		this.impl = impl;
		this.params = params;

		switch (impl.type)
		{
			case null:
			case KFunction(f):
				var minArgs:Int = f.args.length;

				for (arg in f.args)
				{
					if (arg.opt)
						minArgs--;
				}

				if (params == null || params.length < minArgs)
				{
					var args = f.args.slice(f.args.length - minArgs + params.length).map(a -> a.name + ':' + Tools.typeToString(a.t)).join(', ');

					throw 'Not enough arguments, expected $args';
				}
				else if (params.length > f.args.length)
				{
					throw 'Too many arguments';
				}

			default:
		}
	}

	public function equals(e:ScriptedEnumInstance):Bool
	{
		if (e == null)
			return false;

		final params:Array<Dynamic> = getParameters();
		final params2:Array<Dynamic> = e.getParameters();

		if (impl != e.impl)
			return false;

		if ((params == null) != (params2 == null))
			return false;

		if (params == null)
			return true;

		if (params.length != params2.length)
			return false;

		for (i in 0...params.length)
		{
			final obj1:Dynamic = params[i];
			final obj2:Dynamic = params2[i];

			if (obj1 is ScriptedEnumInstance)
			{
				if (obj2 is EnumPattern)
				{
					cast(obj1, ScriptedEnumInstance).matchPattern(cast obj2);
				}
				else if (!(cast(obj1, ScriptedEnumInstance).equals(cast obj2)))
					return false;
			}
			else if (!Tools.enumEq(cast obj1, cast obj2))
				return false;
		}

		return true;
	}

	public function matchPattern(pattern:EnumPattern):Bool
	{
		switch (pattern)
		{
			case EnumPattern(en, index, args):
				if (en != this.en || this.impl.index != index)
					return false;

				final params:Array<Dynamic> = getParameters();

				for (i in 0...params.length)
				{
					if (!Tools.enumEq(params[i], args[i]))
						return false;
				}

			case WildcardPattern:

			case VarPattern(v):
				v(this);
		}
		return true;
	}

	public function getName():String
	{
		return impl.name;
	}

	public function getParameters():Array<Dynamic>
	{
		return params;
	}

	public function getIndex():Int
	{
		return impl.index;
	}

	public function toString():String
	{
		final params:Array<Dynamic> = getParameters();

		return params != null ? impl.name + '(' + params.join(', ') + ')' : impl.name;
	}
}
