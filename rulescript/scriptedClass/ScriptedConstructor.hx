package rulescript.scriptedClass;

abstract class ScriptedConstructor
{
	public var superConstructor:ScriptedConstructor;

	public var lastSuperConstructor(get, never):ScriptedConstructor;

	public function new(superConstructor)
	{
		this.superConstructor = superConstructor;
	}

	abstract public function initCall(args:Array<Dynamic>):Void;

	public function preCall():Void
	{
		if (superConstructor != null)
		{
			superConstructor.initCall(getSuperArgs());
			superConstructor.preCall();
		}
	}

	abstract public function getSuperArgs():Array<Dynamic>;

	public function postCall():Void
	{
		if (superConstructor != null)
		{
			superConstructor.postCall();
		}
	}

	private function get_lastSuperConstructor()
	{
		var current:ScriptedConstructor = this;
		while (current.superConstructor != null)
			current = current.superConstructor;
		return current;
	}
}
