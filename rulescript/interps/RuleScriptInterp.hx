package rulescript.interps;

import hscript.Interp;
import rulescript.interps.interp.RSInterpAccess;

class RuleScriptInterp extends Interp implements IInterp
{
	public var access:InterpAccess;

	public function new()
	{
		access ??= new RSInterpAccess(this);
		super();
	}
}
