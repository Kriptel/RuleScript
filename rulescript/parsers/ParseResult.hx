package rulescript.parsers;

import hscript.Expr;

enum ParseResult
{
	Expression(e:Expr);
	Module(m:Array<ModuleDecl>);
	Custom<T>(o:T);
}
