package rulescript.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if macro
class ExprMacro
{
	public static function build():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		var pos = Context.currentPos();

		for (field in fields)
			if (field.name == 'EFor' || field.name == 'EVar')
				fields.remove(field);

		var newFields:Map<String, Expr> = [
			'EPackage' => macro function(path:String) {},

			'EImport' => macro function(name:String, star:Bool, alias:String, func:String) {},
			'EUsing' => macro function(name:String) {},

			'EVar' => macro function(n:String, ?t:CType, ?e:Expr, ?global:Bool) {},
			'EProp' => macro function(n:String, g:String, s:String, ?t:CType, ?e:Expr, ?global:Bool) {},

			'EFor' => macro function(key:String, it:Expr, e:Expr, ?value:String) {},

			'ETypeVarPath' => macro function(path:Array<String>) {}
		];

		for (key => value in newFields)
			fields.push({
				name: key,
				kind: FFun(MacroTools.toFunction(value)),
				pos: pos
			});

		return fields;
	}

	public static function buildToken():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		var pos = Context.currentPos();

		var newFields:Map<String, Expr> = ['TApostr' => macro function() {},];

		for (key => value in newFields)
			fields.push({
				name: key,
				kind: FFun(MacroTools.toFunction(value)),
				pos: pos
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

		var newFields:Map<String, Expr> = [
			'DImport' => macro function(name:Array<String>, star:Bool, ?alias:String, ?func:String) {},
			'DUsing' => macro function(name:String) {},
			'DAbstract' => macro function(c:rulescript.Abstracts.AbstractDecl) {}
		];

		for (key => value in newFields)
			fields.push({
				name: key,
				access: [],
				kind: FFun(MacroTools.toFunction(value)),
				pos: pos,
			});

		return fields;
	}

	public static function buildInterpDefaults():Array<Field>
		return addDefaultPattern('expr');

	public static function buildParserDefaults():Array<Field>
		return addDefaultPattern('tokenString', null, macro '');

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
											case ESwitch(_e, cases, edef):
												e.expr = ESwitch(_e, cases, edef ?? expr ?? macro {});
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
}
#end
