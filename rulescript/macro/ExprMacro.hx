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
			if (field.name == 'EVar')
				fields.remove(field);

		var newFields:Map<String, Expr> = [
			'EPackage' => macro function(path:String) {},

			'EImport' => macro function(name:String, star:Bool, alias:String, func:String) {},
			'EUsing' => macro function(name:String) {},

			'EVar' => macro function(n:String, ?t:CType, ?e:Expr, ?global:Bool, ?isFinal:Bool) {},
			'EProp' => macro function(n:String, g:String, s:String, ?t:CType, ?e:Expr, ?global:Bool) {},
			'ETypeVarPath' => macro function(path:Array<String>) {},
			'EUntyped' => macro function(e:Expr) {},
			'ECast' => macro function(e:Expr, ?t:CType) {},
			'EMapDecl' => macro function(exprs:Array<Expr>) {}

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
			'DAbstract' => macro function(c:rulescript.types.decl.AbstractDecl) {},
			'DEnum' => macro function(c:rulescript.types.decl.EnumDecl) {}
		];

		for (key => value in newFields)
			fields.push({
				name: key,
				access: [],
				kind: FFun(MacroTools.toFunction(value)),
				pos: pos
			});

		return fields;
	}

	public static function buildFieldAccess():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		fields.push({
			name: 'AFinal',
			access: [],
			kind: FVar(null, null),
			pos: Context.currentPos()
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
		return addDefaultPattern('expr', null, macro
			{
				switch (rulescript.Tools.getExpr(e))
				{
					case EPackage(path):
						add('package $path');
					case EImport(name, star, alias, func):
						add('import ');
						add(name);
						if (star)
						{
							add('.*');
						}
						else
						{
							if (func != null)
								add('.$func');
							if (alias != null)
								add(' as $alias');
						}
					case EUsing(name):
						add('using $name');
					case EUntyped(e):
						add('untyped ');
						expr(e);
					case _:
						add('???');
				}
			});

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
