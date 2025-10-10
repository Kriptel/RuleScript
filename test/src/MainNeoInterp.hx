package;

import Main.*;
import rulescript.interps.NeoInterp;
import tests.NeoTest;

function test()
{
	script.interp = new NeoInterp();

	final neoTest = new NeoTest();
	neoTest.script = script;

	neoTest.test();
}
