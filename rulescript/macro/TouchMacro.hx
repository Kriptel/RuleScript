package rulescript.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Field;

class TouchMacro {
	public static macro function touch():Array<Field> {
		var __touch = Std.string(Date.now().getTime());
	
		var fields = Context.getBuildFields();
		fields.push({
			name: '__touch',
			pos: Context.currentPos(),
			access: [APrivate, AStatic, AInline],
			kind: FVar(macro : String, macro $v{__touch})
		});
		return fields;
	}
}
