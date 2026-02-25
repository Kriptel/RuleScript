package rulescript.interps.interp;

import hscript.Expr;
import rulescript.scriptedClass.ScriptedConstructor;

@:access(rulescript.interps.RuleScriptInterp)
class RSInterpConstructor extends ScriptedConstructor
{
	var interp:RuleScriptInterp;
	var oldStackSize:Int;

	var constructorLocals:Map<String, {r:Dynamic}>;

	public var params:Array<Argument>;
	public var preExpr:Expr;
	public var superCallArgs:Array<Expr>;
	public var postExpr:Expr;

	public function new(superContst:ScriptedConstructor, interp, params, preExpr, ?superCallArgs, postExpr)
	{
		super(superContst);

		this.params = params;
		this.interp = interp;
		this.preExpr = preExpr;
		this.superCallArgs = superCallArgs;
		this.postExpr = postExpr;
	}

	var args:Array<Dynamic>;

	function initCall(callArgs:Array<Dynamic>)
	{
		this.args = callArgs;

		var hasOpt:Bool = false;
		var hasRest:Bool = false;
		var minParams = 0;

		for (p in params)
		{
			if (Tools.isRest(p.t))
			{
				if (params.indexOf(p) == params.length - 1)
					hasRest = true;
				else
					interp.error(ECustom("Rest should only be used for the last function argument"));
			}

			if (p.opt)
				hasOpt = true;
			else
				minParams++;
		}

		if (((args == null) ? 0 : args.length) != params.length)
		{
			if (args.length < minParams && (!hasRest && args.length + 1 < minParams))
			{
				var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams + " for function 'new'";
				interp.error(ECustom(str));
			}

			var args2 = [];
			var extraParams = args.length - minParams;
			var pos = 0;
			for (p in params)
			{
				if (hasRest && Tools.isRest(p.t))
					args2.push([for (i in pos...args.length) args[i]]);
				else
				{
					if (p.opt)
					{
						if (extraParams > 0)
						{
							args2.push(args[pos++]);
							extraParams--;
						}
						else
							args2.push(null);
					}
					else
						args2.push(args[pos++]);
				}
			}
			args = args2;
		}
		else if (hasRest)
			args.push([args.pop()]);
	}

	var oldLocals:Map<String, {r:Dynamic}>;
	var oldDepth:Int;

	override function preCall()
	{
		this.oldStackSize = interp.declared.length;

		oldLocals = interp.locals;
		oldDepth = interp.depth++;

		constructorLocals = interp.locals = interp.duplicate(oldLocals);
		for (i in 0...params.length)
			interp.locals.set(params[i].name, {r: args[i]});

		interp.skipNextRestore = true;
		interp.exprReturn(preExpr);

		super.preCall();
	}

	function getSuperArgs():Array<Dynamic>
	{
		return superCallArgs.map(e -> interp.argExpr(e));
	}

	override function postCall()
	{
		super.postCall();

		interp.locals = constructorLocals;

		interp.skipNextRestore = true;
		interp.exprReturn(postExpr);

		interp.restore(oldStackSize);
		interp.locals = oldLocals;
		interp.depth = oldDepth;
	}
}
