package rulescript.macro;

class NeoMacro
{
	public static macro function scope(e:haxe.macro.Expr):haxe.macro.Expr
	{
		return macro
		{
			final __v = lastValues.length;

			$e;

			restore(__v);
		}
	}

	public static macro function skippable(e:haxe.macro.Expr):haxe.macro.Expr
	{
		return macro
		{
			final skipID:Int = addInt(-1);

			{
				$e;
			}

			setInt(skipID, currentPos());
		}
	}
}
