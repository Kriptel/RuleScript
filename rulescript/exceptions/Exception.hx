package rulescript.exceptions;

class Exception
{
	public var kind:ExceptionDef;

	public function new(kind:ExceptionDef)
	{
		this.kind = kind;
	}

	public function toString():String
	{
		return exceptionToString(kind);
	}

	public static function exceptionToString(e:ExceptionDef)
	{
		return switch (e)
		{
			case EUnsupportedParseOutput:
				'Unsupported parse output format.';
			case ENullExpr:
				'Null value should be expression.';
		}
	}
}

enum ExceptionDef
{
	ENullExpr;
	EUnsupportedParseOutput;
}
