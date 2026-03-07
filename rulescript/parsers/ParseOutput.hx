package rulescript.parsers;

import hscript.Expr.ModuleDecl;

enum ParseOutput
{
	Expr(e:hscript.Expr);
	Module(m:Array<ModuleDecl>);
	Custom<T>(o:T);
}
