package test;

@:keep
enum abstract HelloWorldAbstract(String) from String to String
{
	public static function rulescriptPrint():HelloWorldAbstract
	{
		return 'Hello World';
	}

	var RULESCRIPT:String = 'Rulescript';

	var hello:String;

	var world:String;
}
