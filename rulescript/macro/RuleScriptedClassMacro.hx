package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import rulescript.macro.MacroTools;

class RuleScriptedClassMacro
{
	static var aliasMap:Map<String, haxe.macro.Type> = [];

	public static macro function build():Array<Field>
	{
		var pos = Context.currentPos();
		var fields:Array<Field> = Context.getBuildFields();

		var typefields:Map<String, ClassField> = [];

		var curType = Context.getLocalClass().get();

		if (curType.meta.has(':noBuild'))
			return fields;

		curType = curType.superClass.t.get();

		var constructor = curType.constructor?.get();

		var inlinedFields:Array<String> = [];
		while (curType != null)
		{
			for (field in curType.fields.get())
			{
				if (!inlinedFields.contains(field.name) && field.kind.match(FMethod(MethInline)))
				{
					inlinedFields.push(field.name);
				}

				if (!typefields.exists(field.name) && !field.isFinal && field.kind.match(FMethod(_)) && !inlinedFields.contains(field.name))
					typefields.set(field.name, field);
			}
			curType = curType.superClass?.t.get();

			constructor ??= curType.constructor?.get();
		}

		createAliasMap();

		curType = Context.getLocalClass().get();

		var ignoredFields:Array<String> = [];
		for (meta in curType.meta.extract(':ignoreFields'))
		{
			switch (meta.params[0].expr)
			{
				case EArrayDecl(values):
					for (value in values)
						switch (value.expr)
						{
							case EConst(CIdent(s)):
								ignoredFields.push(s);
							default:
						}

				default:
			}
		};

		final forceOverride = curType.meta.has(':forceOverride');
		var forceOverrideFields:Array<String> = null;

		if (forceOverride)
		{
			for (meta in curType.meta.extract(':forceOverride'))
			{
				if (meta.params[0] != null)
					switch (meta.params[0].expr)
					{
						case EArrayDecl(values):
							forceOverrideFields ??= [];

							for (value in values)
								switch (value.expr)
								{
									case EConst(CIdent(s)):
										forceOverrideFields.push(s);
									default:
								}
						default:
					}
			}
		}

		for (name => field in typefields)
		{
			final forceOverrideField = forceOverrideFields?.contains(name) ?? forceOverride;
			if (!ignoredFields.contains(name))
				fields.push(overrideField(field, forceOverrideField));
		}

		if (constructor.isFinal)
			Context.error("Constructor can't be final in RuleScriptedClass", pos);

		final strict = curType.meta.has(':strictScriptedConstructor') || curType.meta.has(':strictConstructor');

		final forceOverrideConstructor = forceOverrideFields?.contains('new') ?? forceOverride;

		fields.push({
			name: 'new',
			access: [APublic],
			kind: FFun(createConstructor(constructor, strict, forceOverrideConstructor)),
			pos: pos
		});

		fields.push({
			name: '__rulescript_strict',
			access: [AStatic, AFinal],
			kind: FVar(macro :Bool, macro $v{strict}),
			pos: pos
		});

		fields.push({
			name: '__rulescript_type',
			access: [APublic],
			kind: FProp('get', 'never', macro :rulescript.types.ScriptedType.TypeID),
			pos: pos,
			meta: [{name: ':noCompletion', pos: pos}]
		});

		fields.push({
			name: '__rulescript',
			access: [APublic],
			kind: FVar(macro :rulescript.RuleScript),
			pos: pos,
			meta: [{name: ':noCompletion', pos: pos}]
		});

		final functions = [
			'getVariables' => macro function():Map<String, Dynamic>
			{
				return __rulescript.variables;
			},
			'variableExists' => macro function(name:String):Bool
			{
				return __rulescript.variables.exists(name);
			},
			'getVariable' => macro function(name:String):Dynamic
			{
				return __rulescript.variables[name];
			},
			'setVariable' => macro function(name:String, value:Dynamic):Dynamic
			{
				return __rulescript.variables[name] = value;
			},
			'get___rulescript_type' => macro function():rulescript.types.ScriptedType.TypeID
			{
				return rulescript.types.ScriptedType.TypeID.CLASS;
			}
		];

		for (name => func in functions)
			fields.push({
				name: name,
				access: [APublic],
				kind: FFun(MacroTools.toFunction(func)),
				pos: pos
			});

		return fields;
	}

	static function createConstructor(constructor:ClassField, strict:Bool = false, forceOverride:Bool):Function
	{
		var args = null;

		switch (constructor.type)
		{
			case TFun(_args, ret):
				args = _args;
			case TLazy(type):
				switch (type())
				{
					case TFun(_args, ret):
						args = _args;
					default:
				};
			default:
		}

		var fieldArgs = strict ? [for (argument in args) macro $i{argument.name}] : [macro args];

		var scriptSuperCall = [
			for (i in 0...args.length)
				macro superCallArgs[$v{i}]
		];

		var funcArgs:Array<FunctionArg> = [
			{
				name: 'typeName',
				type: macro :String
			}
		];

		if (strict)
			funcArgs = funcArgs.concat([
				for (arg in args)
					{
						name: arg.name,
						opt: arg.opt,
						type: forceOverride ? macro :Dynamic : getOverrideType(arg.t)
					}
			]);
		else
			funcArgs.push({
				name: 'args',
				opt: true,
				type: macro :Array<Dynamic>
			});

		return {
			args: funcArgs,
			expr: Context.getLocalClass().get().superClass != null ? macro
				{
					__rulescript = rulescript.scriptedClass.RuleScriptedClassUtil.buildRuleScript(typeName, this);

					$e{!strict ? macro args ??= [] : macro {}} // If args equals null

					if (__rulescript.access.hasConstructor)
					{
						final c = __rulescript.access.createConstructor($
							{
								if (strict)
									macro $a{fieldArgs}
								else
									macro args
							});

						c.pre();

						final superCallArgs:Array<Dynamic> = c.getSuperArgs();

						super($a{scriptSuperCall});
						c.post();
					}
					else
					{
						super($a
							{
								strict ? fieldArgs : [for (i in 0...args.length) macro args[$v{i}]]
							});
					}
				} : macro {},
			params: forceOverride ? [] : [for (param in constructor.params) {name: param.name}]
		}
	}

	static function overrideField(field:ClassField, forceOverride:Bool):Field
	{
		var kind = null;

		var fieldName = field.name;

		var tFunToExpr:(Array<ClassFunctionArg>, ret:haxe.macro.Type) -> Function = (args, ret) ->
		{
			var fieldArgs = [
				for (argument in args)
					macro $i{argument.name}
			];

			return {
				args: [
					for (id => arg in args)
						{
							name: arg.name,
							type: forceOverride ? macro :Dynamic : getOverrideType(arg.t),
							value: switch (Context.getTypedExpr(field.expr()).expr)
							{
								case EFunction(kind, f):
									f.args[id].value;
								default:
									null;
							}
						}
				],
				ret: forceOverride ? null : getOverrideType(ret),
				expr: macro
				{
					return if (!__rulescript.access.isSuperCall && __rulescript.access.variableExists($v{field.name}))
					{
						__rulescript.access.getVariable($v{field.name})($a{fieldArgs});
					}
					else
					{
						cast super.$fieldName($a{fieldArgs});
					}
				},
				params: if (forceOverride)
					[]
				else
					[
						for (param in field.params)
							{name: param.name}
					]
			}
		}

		switch (field.type)
		{
			case TFun(args, ret):
				kind = tFunToExpr(args, ret);
			case TLazy(type):
				switch (type())
				{
					case TFun(args, ret):
						kind = tFunToExpr(args, ret);
					default:
				};
			default:
		}

		return {
			name: field.name,
			access: [AOverride],
			kind: FFun(kind),
			pos: Context.currentPos()
		};
	}

	inline static function getOverrideType(type:haxe.macro.Type):ComplexType
	{
		return type != null ? Context.toComplexType(transformTypeParams(type)) : null;
	}

	static function transformTypeParams(type:haxe.macro.Type):haxe.macro.Type
	{
		switch (type)
		{
			case TInst(t, params):
				var _t = t;
				var _params = params;

				var className = Context.getLocalClass().get().name;

				while (aliasMap.exists(className + _t.toString()))
				{
					_t = switch (aliasMap.get(className + _t.toString()))
					{
						case TInst(t, params):
							_params = params;
							t;
						default: null;
					};
				}

				for (id => param in _params)
					_params[id] = transformTypeParams(param);

				type = TInst(_t, _params);
			case TFun(args, ret):
				var _args = args;
				var _ret = ret;

				for (arg in _args)
				{
					arg.t = transformTypeParams(arg.t);
				}

				type = TFun(_args, transformTypeParams(_ret));
			case TAbstract(t, params):
				type = TAbstract(t, [for (param in params) transformTypeParams(param)]);
			default:
				null;
		}

		return type;
	}

	static function createAliasMap():Void
	{
		var t:ClassType = Context.getLocalClass().get();

		while (t != null)
		{
			for (id => param in t.superClass?.params ?? [])
			{
				switch (param)
				{
					case TInst(_t, params):
						aliasMap.set(Context.getLocalClass().get().name + switch (t.superClass?.t.get().params[id].t)
						{
							case TInst(t, params):
								t.toString();
							default: null;
						}, param);
					default:
				}
			}
			t = t.superClass?.t.get();
		}
	}
}
#end
