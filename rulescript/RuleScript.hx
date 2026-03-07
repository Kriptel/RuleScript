package rulescript;

import rulescript.internal.utils.Castable;
import rulescript.interps.IInterp;
import rulescript.parsers.IParser;

class RuleScript
{
	public var parser:Castable<IParser>;
	public var interp:Castable<IInterp>;
	public var context:Castable<Context>;

	public function new(?parser:IParser, ?interp:IInterp, ?context:Context)
	{
		this.parser = parser;
		this.interp = interp;
		this.context = context;
	}
}
