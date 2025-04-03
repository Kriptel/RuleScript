package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class CommandMacro
{
	macro static function build():Array<Field>
	{
		final fields = haxe.macro.Context.getBuildFields();

		final list = [
			for (field in fields)
				if (field.kind.match(FVar(_)))
					macro $
					{
						switch (field.kind)
						{
							case FVar(_, e):
								e;
							default:
								null;
						}
					}
					=> $v{field.name}
		];

		fields.push({
			name: 'COMMAND_LIST',
			access: [AStatic, APublic],
			pos: Context.currentPos(),
			kind: FVar(null, macro [$a{list}])
		});

		return fields;
	}
}
#end
