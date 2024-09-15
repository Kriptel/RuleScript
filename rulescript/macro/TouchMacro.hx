package rulescript.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Field;

class TouchMacro
{
	public static macro function touch():Array<Field>
	{
		var __touch = Std.string(Math.random() * 0x7FFFFFFF);

		var fields = Context.getBuildFields();
		fields.push({
			name: '__touch',
			pos: Context.currentPos(),
			access: [APrivate, AStatic, AInline],
			kind: FVar(macro :String, macro $v{__touch}),
			meta: [{pos: Context.currentPos(), name: ':noCompletion'}]
		});
		return fields;
	}
}
