package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import rulescript.macro.MacroTools;

class RuleScriptedClass
{
	static var aliasMap:Map<String, haxe.macro.Type> = [];

	public static macro function build():Array<Field>
	{
		var pos = Context.currentPos();
		var fields:Array<Field> = Context.getBuildFields();

		var typefields:Map<String, ClassField> = [];

		var curType = Context.getLocalClass().get();

		var constructor = curType.constructor?.get();
		while (curType != null)
		{
			for (field in curType.fields.get())
			{
				if (!typefields.exists(field.name) && !field.isFinal && field.kind.match(FMethod(_)) && !field.kind.match(FMethod(MethInline)))
					typefields.set(field.name, field);
			}
			curType = curType.superClass?.t.get();

			constructor ??= curType.constructor?.get();
		}

		createAliasMap();

		for (name => field in typefields)
		{
			fields.push(overrideField(field));
		}

		fields.push({
			name: 'new',
			access: [APublic],
			kind: FFun(createConstructor(constructor)),
			pos: Context.currentPos()
		});

		fields.push({
			name: '__rulescript',
			access: [],
			kind: FVar(macro :rulescript.RuleScript),
			pos: Context.currentPos()
		});

		return fields;
	}

	static function createConstructor(constructor:ClassField):Function
	{
		var args = null;

		var ret = null;

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

		var fieldArgs = [for (argument in args) macro $i{argument.name}];

		var funcArgs:Array<FunctionArg> = [
			{
				name: 'typeName',
				type: macro :String
			}
		];

		funcArgs = funcArgs.concat([
			for (arg in args)
				{
					name: arg.name,
					opt: arg.opt,
					type: getOverrideType(arg.t)
				}
		]);

		return {
			args: funcArgs,
			expr: Context.getLocalClass().get().superClass != null ? macro
				{
					__rulescript = rulescript.scriptedClass.RuleScriptedClassUtil.buildRuleScript(typeName, this);

					if (__rulescript.interp.variables.exists('new'))
					{
						__rulescript.interp.variables.get('new')($a{fieldArgs});
					}
					else
					{
						super($a{fieldArgs});
					}
				} : macro {},
			params: [for (param in constructor.params) {name: param.name}]
		}
	}

	static function overrideField(field:ClassField):Field
	{
		var kind = null;

		var fieldName = field.name;

		var fieldParams = [for (param in field.params) macro $i{param.name}];

		var tFunToExr:(Array<ClassFunctionArg>, ret:haxe.macro.Type) -> Function = (args, ret) ->
		{
			var fieldArgs = [for (argument in args) macro $i{argument.name}];
			return {
				args: [
					for (id => arg in args)
						{
							name: arg.name,
							type: getOverrideType(arg.t),
							value: switch (Context.getTypedExpr(field.expr()).expr)
							{
								case EFunction(kind, f):
									f.args[id].value;
								default:
									null;
							}
						}
				],
				ret: getOverrideType(ret),
				expr: macro
				{
					return if (__rulescript.interp.variables.exists($v{field.name}))
					{
						__rulescript.interp.variables.get($v{field.name})($a{fieldArgs});
					}
					else
					{
						super.$fieldName($a{fieldArgs});
					}
				},
				params: [for (param in field.params) {name: param.name}]
			}
		}

		switch (field.type)
		{
			case TFun(args, ret):
				kind = tFunToExr(args, ret);
			case TLazy(type):
				switch (type())
				{
					case TFun(args, ret):
						kind = tFunToExr(args, ret);
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
		return Context.toComplexType(transformTypeParams(type));
	}

	static function transformTypeParams(type:haxe.macro.Type):haxe.macro.Type
	{
		switch (type)
		{
			case TInst(t, params):
				var _t = t;
				var _params = params;

				while (aliasMap.exists(_t.toString()))
				{
					_t = switch (aliasMap.get(_t.toString()))
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
						aliasMap.set(switch (t.superClass?.t.get().params[id].t)
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
