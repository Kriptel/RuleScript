package rulescript.scriptedClass;

import hscript.Expr;
import rulescript.interps.RuleScriptInterp;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.ScriptedTypeUtil;

using rulescript.Tools;

abstract ScriptedClassType(Dynamic) from ScriptedClass to ScriptedClass to Expr
{
	public var isExpr(get, never):Bool;

	inline function get_isExpr():Bool
	{
		return !(this is ScriptedClass);
	}

	@:deprecated
	@:from inline static function fromExpr(expr:Expr):ScriptedClassType
	{
		return cast expr;
	}
}

class RuleScriptedClassUtil
{
	public static var types:Map<String, ScriptedClassType> = [];

	public static var buildBridge:(typePath:String, superInstance:Dynamic) -> RuleScript;

	public static var autoWrappers:Map<String, Dynamic>;

	public static var importHxDecls:Map<String, Array<hscript.Expr.ModuleDecl>> = new Map();

	public static function registerAutoWrapper(nativeName:String, wrapperClass:Dynamic):Void
	{
		if (autoWrappers == null) 
		{
			autoWrappers = new Map<String, Dynamic>();
		}
		
		autoWrappers.set(nativeName, wrapperClass);
	}

	public static function buildRuleScript(typePath:String, superInstance:Dynamic):RuleScript
	{
		return if (buildBridge != null)
		{
			buildBridge(typePath, superInstance);
		}
		else
		{
			var type:ScriptedClassType = types[typePath] ?? ScriptedTypeUtil.resolveScript(typePath);

			var rulescript = new rulescript.RuleScript();
			rulescript.superInstance = superInstance;
			rulescript.scriptName = typePath;
			if (rulescript.interp is RuleScriptInterp)
				cast(rulescript.interp, RuleScriptInterp).skipNextRestore = true;

			if (type.isExpr)
			{
				rulescript.execute(cast type);

				rulescript;
			}
			else
			{
				var cl:ScriptedClass = cast type;

				buildScriptedClass(cl, rulescript);
			}
			rulescript;
		}
	}

	public static function registerRuleScriptedClass(typePath:String, classType:ScriptedClassType):ScriptedClassType
	{
		return types[typePath] = classType;
	}

	public static function getClass(typePath:String):ScriptedClass
	{
		return cast types[typePath];
	}

	public static function listScriptClasses():Array<String>
	{
		var result:Array<String> = [];
		for (key in types.keys())
		{
			result.push(key);
		}
		return result;
	}

	public static function buildScriptedClass(cl:ScriptedClass, rulescript:RuleScript):Void
	{
		rulescript.access.setVariable('new', () -> {});

		var list = [];

		var currentClass:ScriptedClass = cl;

		while (currentClass != null)
		{
			list.insert(0, currentClass);

			if (currentClass.superClass is ScriptedClass)
				currentClass = currentClass.superClass;
			else
				currentClass = null;
		}

		var superFields:Array<String> = [];
		
		if (cl.nativeClass != null) {
			var nativeFields = Type.getInstanceFields(cast cl.nativeClass);
			if (nativeFields != null)
				for (f in nativeFields) superFields.push(f);
		}
		
		var currentSuper = cl.superClass;
		while (currentSuper != null && currentSuper is ScriptedClass) {
			var sc:ScriptedClass = cast currentSuper;
			if (sc.impl != null && sc.impl.fields != null) {
				for (f in sc.impl.fields)
					if (!superFields.contains(f.name)) superFields.push(f.name);
			}
			currentSuper = sc.superClass;
		}

		if (cl.impl != null && cl.impl.fields != null) {
			for (field in cl.impl.fields) {
				if (field.name == "new" || field.access.contains(AStatic)) continue;
				
				var isOverride = field.access.contains(AOverride);
				var parentHasField = superFields.contains(field.name);

				if (isOverride && !parentHasField)
					throw new haxe.Exception('Field "' + field.name + '" is declared as override, but overrides nothing in class "' + cl.className + '".');
				else if (!isOverride && parentHasField)
					throw new haxe.Exception('Method "' + field.name + '" overrides a parent field, but is missing the "override" keyword in class "' + cl.className + '".');
			}
		}

		var exprList:Array<Expr> = [];

		for (cl in list)
		{
			var decls = injectImportHx(cl.module.sharedDecls);

			final exprs = Tools.moduleDeclsToExpr(decls,
				{classImpl: cl.impl, isScriptedClass: true, fieldFilter: f -> !f.access.contains(AStatic)});

			final exprs:Array<Expr> = switch (exprs.getExpr())
			{
				case EBlock(exprs): exprs;
				case e: [exprs];
			}

			for (expr in exprs)
				switch (Tools.getExpr(expr))
				{
					default:
						exprList.push(expr);
				}
		}

		rulescript.execute(EBlock(exprList).toExpr());
	}

	public static function getImportHxDecls(pack:String):Array<hscript.Expr.ModuleDecl>
	{
		var decls:Array<hscript.Expr.ModuleDecl> = [];
		
		if (importHxDecls.exists("")) 
			decls = decls.concat(importHxDecls.get(""));
			
		if (pack == null || pack == "") 
			return decls;

		var currentPack = "";
		for (part in pack.split(".")) 
		{
			if (part == "") continue;
			currentPack += (currentPack == "" ? "" : ".") + part;
			if (importHxDecls.exists(currentPack)) 
				decls = decls.concat(importHxDecls.get(currentPack));
		}
		
		return decls;
	}

	public static function injectImportHx(moduleDecls:Array<hscript.Expr.ModuleDecl>):Array<hscript.Expr.ModuleDecl>
	{
		if (moduleDecls == null) return [];
		var decls = moduleDecls.copy();
		var insertIndex = 0;
		var pack = "";
		
		for (i in 0...decls.length)
		{
			if (Type.enumConstructor(decls[i]) == "DPackage")
			{
				var path:Array<String> = Type.enumParameters(decls[i])[0];
				pack = path.join(".");
				insertIndex = i + 1;
				break;
			}
		}

		var importDecls = getImportHxDecls(pack);
		for (i in 0...importDecls.length)
		{
			decls.insert(insertIndex + i, importDecls[i]);
		}
		
		return decls;
	}
}
