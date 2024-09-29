package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
import rulescript.macro.MacroTools;

class RuleScriptedClass
{
	public static macro function build():Array<Field>
	{
		var pos = Context.currentPos();
		var fields:Array<Field> = Context.getBuildFields();

		var typefields:Map<String, ClassField> = [];

		var curType = Context.getLocalClass().get();

		while (curType != null)
		{
			for (field in curType.fields.get())
			{
				if (!typefields.exists(field.name) && !field.kind.match(FMethod(MethInline)))
					typefields.set(field.name, field);
			}
			curType = curType.superClass?.t.get();
		}

		for (name => field in typefields)
		{
			fields.push(overrideField(field));
		}

		fields.push({
			name: 'new',
			access: [APublic],
			kind: FFun(MacroTools.toFunction(macro function(typeName:String) $
			{
				Context.getLocalClass().get().superClass != null ? macro
					{
						__rulescript = rulescript.scriptedClass.RuleScriptedClassUtil.buildRuleScript(typeName, this);
						super();
					} : macro {}
			})),
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
					for (arg in args)
						{
							name: arg.name,
							opt: arg.opt,
							type: Context.toComplexType(arg.t)
						}
				],
				ret: Context.toComplexType(ret),
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
}
#end
