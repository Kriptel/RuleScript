package rulescript;

enum Property
{
	DEFAULT;
	GET(f:() -> Dynamic);
	SET(f:Dynamic->Dynamic);
	NULL;
	DYNAMIC(f:?Dynamic->Dynamic);
	NEVER;
}

class RuleScriptProperty
{
	var _get:Property;
	var _set:Property;

	@:allow(rulescript.RuleScriptInterp)
	var _lazyValue:() -> Dynamic;

	@:isVar public var value(get, set):Dynamic;

	var _inProperty:Bool = false;

	public function new(?get:Property = DEFAULT, ?set:Property = DEFAULT)
	{
		this._get = get;
		this._set = set;
	}

	function get_value():Dynamic
	{
		if (_inProperty)
			return this.value;

		initLazy();

		_inProperty = true;

		var v:Dynamic = switch (_get)
		{
			case DEFAULT | NULL: this.value;
			case GET(f): f();
			case SET(f): throw 'Custom property accessor is no longer supported, please use `get`';
			case DYNAMIC(f): f();
			case NEVER: throw 'This expression cannot be accessed for reading';
		}

		_inProperty = false;

		return v;
	}

	function set_value(v:Dynamic):Dynamic
	{
		if (_inProperty)
			return this.value = v;

		initLazy();

		_inProperty = true;

		var v:Dynamic = switch (_set)
		{
			case DEFAULT | NULL: this.value = v;
			case GET(f): throw 'Custom property accessor is no longer supported, please use `set`';
			case SET(f): f(v);
			case DYNAMIC(f): f(v);
			case NEVER: throw 'This expression cannot be accessed for writing';
		}

		_inProperty = false;

		return v;
	}

	inline function initLazy()
	{
		if (_lazyValue != null)
		{
			var newValue = _lazyValue();
			_lazyValue = null;
			set_value(newValue);
		}
	}
}
