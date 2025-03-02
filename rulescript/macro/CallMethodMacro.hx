package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class CallMethodMacro
{
	#if macro
	macro public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

		for (i in [1, 2, 3, 4, 6, 8, 12])
			fields.push({
				name: 'callMethod' + i,
				access: [AStatic, APublic],
				kind: FFun({
					args: {
						var args:Array<FunctionArg> = [{name: 'f', type: macro :Array<Dynamic>->Dynamic}];
						for (argNum in 1...i + 1)
							args.push({name: 'a$argNum', type: macro :Dynamic, opt: true});

						args;
					},
					expr: {
						var args:Array<Expr> = [for (argNum in 1...i + 1) macro $i{'a$argNum'}];
						macro return f([$a{args}]);
					}
				}),
				pos: pos,
				meta: [{name: ':noCompletion', pos: pos}]
			});

		return fields;
	}
	#end

	@:allow(rulescript.Tools) macro static function __hl_callMethod():haxe.macro.Expr
	{
		var e:Expr = {
			expr: ESwitch(macro need, [
				for (i in 9...13)
				{
					var t:haxe.macro.ComplexType = TFunction([for (i in 0...i) macro :Dynamic], macro :Dynamic);
					{
						values: [macro $v{i}],
						guard: null,
						expr: macro
						{
							$e{{expr: EVars([{name: 'f', type: t, expr: macro cast func}]), pos: Context.currentPos()}};
							f($a
								{
									{
										[for (i in 0...i) macro args[$v{i}]];
									}
								});
						}
					}
				}
			], macro throw 'Too many arguments'),
			pos: Context.currentPos()
		}

		return e;
	}
}
