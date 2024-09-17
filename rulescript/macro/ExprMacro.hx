package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class ExprMacro
{
	public static function build():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		var pos = Context.currentPos();

		fields.push({
			name: 'EPackage',
			access: [],
			kind: FFun(toFunction(macro function(path:String) {})),
			pos: pos,
		});

		fields.push({
			name: 'EImport',
			access: [],
			kind: FFun(toFunction(macro function(name:String, star:Bool, alias:String, func:String) {})),
			pos: pos,
		});

		fields.push({
			name: 'EUsing',
			access: [],
			kind: FFun(toFunction(macro function(name:String) {})),
			pos: pos,
		});

		return fields;
	}

	public static function buildModuleDecl():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		var pos = Context.currentPos();

		for (field in fields)
			if (field.name == 'DImport')
				fields.remove(field);

		fields.push({
			name: 'DImport',
			access: [],
			kind: FFun(toFunction(macro function(name:Array<String>, star:Bool, ?alias:String, ?func:String) {})),
			pos: pos,
		});

		fields.push({
			name: 'DUsing',
			access: [],
			kind: FFun(toFunction(macro function(name:String) {})),
			pos: pos,
		});

		return fields;
	}

	public static function buildInterpDefaults():Array<Field>
		return addDefaultPattern('expr');

	public static function buildToolsDefaults():Array<Field>
		return addDefaultPattern('map', addDefaultPattern('iter'), macro expr(e));

	public static function buildPrinterDefaults():Array<Field>
		return addDefaultPattern('expr');

	public static function buildBytesDefaults():Array<Field>
		return addDefaultPattern('doEncode');

	public static function buildCheckerDefaults():Array<Field>
		return addDefaultPattern('typeExpr');

	public static function buildMacroDefaults():Array<Field>
		return addDefaultPattern('convert', null, macro null);

	public static function addDefaultPattern(functionName:String, ?fields:Array<Field>, ?expr:Expr):Array<Field>
	{
		fields ??= Context.getBuildFields();

		var pos = Context.currentPos();

		for (field in fields)
			if (field.name == functionName)
				switch (field.kind)
				{
					case FFun(f):
						{
							var body = switch (f.expr.expr)
							{
								case EBlock(block): block;
								default:
									var a = [f.expr];
									f.expr.expr = EBlock(a);
									a;
							};

							for (i in body)
							{
								switch (i.expr)
								{
									case EReturn(e):
										switch (e.expr)
										{
											case EObjectDecl(fields):
												for (field in fields)
												{
													switch (field.expr.expr)
													{
														case ESwitch(e, cases, edef):
															field.expr.expr = ESwitch(e, cases, edef ?? expr ?? macro {});
														default:
													}
												}
											default:
										}
									case EVars(vars):
										for (variable in vars)
											switch (variable.expr.expr)
											{
												case ESwitch(e, cases, edef):
													variable.expr.expr = ESwitch(e, cases, edef ?? expr ?? macro {});

												default:
											}
									case ESwitch(e, cases, edef):
										i.expr = ESwitch(e, cases, edef ?? expr ?? macro {});
									default:
								}
							}
						}
					default:
				};

		return fields;
	}

	/**
	 * Convert Expr function to function
	 */
	static function toFunction(f:Expr):Function
	{
		return switch (f.expr)
		{
			case EFunction(kind, f):
				f;
			default:
				null;
		}
	}
}
#end
