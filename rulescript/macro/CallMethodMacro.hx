package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class CallMethodMacro
{
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
				pos: pos
			});

		return fields;
	}
}
#end
