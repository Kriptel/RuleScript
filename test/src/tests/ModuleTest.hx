package tests;

import rulescript.parsers.HxParser;

class ModuleTest extends Test
{
	override function test()
	{
		script.getParser(HxParser).mode = MODULE;

		runScript('
				package;

				class HelloWorld
				{
					function main(){
						return true;
					}
				}
			', () ->
			{
				return script.variables.get('main')();
			});

		script.superInstance = {"test": () -> trace('testing super instance')};

		runScript('
			package;

			class HelloWorld
			{
				function main(){
					test();

					return true;
				}
			}
		', () -> script.variables.get('main')());

		script.superInstance = {"replace": () -> trace('testing super instance')};

		runScript('
			package;

			using StringTools;

			class HelloWorld
			{
				function main(){
					var a = {
						b:{
							c:{
								text:"hello"
							}
						}
					};
					trace(a.b.c.text.replace("hello","world"));
				}
			}
		');

		script.variables.get('main')();
	}
}
