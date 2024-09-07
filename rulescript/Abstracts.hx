package rulescript;

import rulescript.macro.AbstractMacro;

using StringTools;

class Abstracts
{
	public static dynamic function resolveAbstract(name:String):Class<Dynamic>
	{
		return Type.resolveClass('rulescript.__abstracts.${name.substring(0, name.lastIndexOf('.') + 1) + '_' + name.substring(name.lastIndexOf('.') + 1)}');
	}
}
