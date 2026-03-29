package rulescript;

import haxe.extern.EitherType;
import hscript.Expr;
import rulescript.exceptions.Exception;
import rulescript.internal.utils.Castable;
import rulescript.interps.IInterp;
import rulescript.interps.InterpAccess;
import rulescript.parsers.IParser;

class RuleScript
{
	/**
	 * The access.
	 */
	public var access(get, never):InterpAccess;

	/**
	 * The parser.
	 */
	public var parser:Castable<IParser>;

	/**
	 * The interpreter.
	 */
	public var interp:Castable<IInterp>;

	/**
	 * The script context handles repeated imports, and public / static variables.
	 */
	public var context:Castable<Context>;

	public function new(?parser:IParser, ?interp:IInterp, ?context:Context)
	{
		this.context = context ?? new Context();

		this.context.initializeScript(this, parser, interp);
	}

	function get_access():InterpAccess
	{
		return interp.access;
	}

	/**
	 * This method allows you to either execute a `Expr` or a string.
	 * pretty self explanatory...
	 * 
	 * @param code Either a `Expr` or a `String`.
	 * @return Dynamic Whether gets returned after executing...
	 */
	public function execute(code:EitherType<String, Expr>):Dynamic
	{
		var expr:Expr = null;

		if (code is String)
		{
			switch (parser.parse(cast code))
			{
				case Expression(e):
					expr = e;
				default:
					throw new Exception(EUnsupportedParseOutput);
			}
		}
		else
		{
			expr = cast code;
		}

		if (expr == null)
			throw new Exception(ENullExpr);

		return access.execute(expr);
	}
}
