package rulescript.scriptedClass;

import hscript.Expr;
import haxe.io.Path;
import rulescript.interps.RuleScriptInterp;
import rulescript.scriptedClass.RuleScriptedClass.ScriptedClass;
import rulescript.types.ScriptedTypeUtil;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using rulescript.Tools;
using StringTools;

abstract ScriptedClassType(Dynamic) from ScriptedClass to ScriptedClass to Expr
{
	public var isExpr(get, never):Bool;
	inline function get_isExpr():Bool return !(this is ScriptedClass);
	@:deprecated @:from inline static function fromExpr(expr:Expr):ScriptedClassType return cast expr;
}

class RuleScriptedClassUtil
{
	public static var types:Map<String, ScriptedClassType> = [];
	public static var buildBridge:(typePath:String, superInstance:Dynamic) -> RuleScript;
	public static var autoWrappers:Map<String, Dynamic>;

	public static var importHxCache:Map<String, Array<hscript.Expr.ModuleDecl>> = new Map();

	public static var fileExists:(path:String) -> Bool = #if sys (path) -> FileSystem.exists(path) #else (path) -> false #end;
	public static var getFileContent:(path:String) -> String = #if sys (path) -> File.getContent(path) #else (path) -> null #end;

	public static function registerAutoWrapper(nativeName:String, wrapperClass:Dynamic):Void
	{
		autoWrappers ??= new Map<String, Dynamic>();
		autoWrappers.set(nativeName, wrapperClass);
	}

	public static function getImportDecls(targetFilePath:String):Array<hscript.Expr.ModuleDecl>
	{
		if (targetFilePath == null || targetFilePath.length == 0 || fileExists == null) 
			return [];

		final normalized = Path.normalize(targetFilePath).split('\\').join('/');

		var dir = Path.directory(normalized);
		if (dir == "." || dir == null) dir = "";

		final parts = dir.split("/").filter(p -> p != "" && p != ".");
		final dirsToCheck:Array<String> = [""];

		var current = "";
		for (part in parts) {
			current = (current == "") ? part : current + "/" + part;
			dirsToCheck.push(current);
		}

		var accumulatedDecls:Array<hscript.Expr.ModuleDecl> = [];
		for (d in dirsToCheck) {
			final importPath = (d == "") ? "import.hx" : d + "/import.hx";

			if (fileExists(importPath)) {
				if (!importHxCache.exists(importPath)) {
					final content = getFileContent != null ? getFileContent(importPath) : null;
					if (content?.trim().length > 0) {
						try {
							final parser = new rulescript.parsers.HxParser();
							parser.allowAll();
							parser.mode = MODULE;
							importHxCache.set(importPath, parser.parseModule(content));
						} catch (e:Dynamic) {
							trace('Error parsing $importPath: $e');
							importHxCache.set(importPath, []);
						}
					} else {
						importHxCache.set(importPath, []);
					}
				}

				final decls = importHxCache.get(importPath);
				if (decls?.length > 0)
					accumulatedDecls = accumulatedDecls.concat(decls);
			}
		}

		return accumulatedDecls;
	}

	public static function applyImportsFromDecls(interp:RuleScriptInterp, decls:Array<hscript.Expr.ModuleDecl>):Void {
		if (decls == null || decls.length == 0) return;
		var importDecls:Array<hscript.Expr.ModuleDecl> = [];
		for (decl in decls) {
			var cname = Type.enumConstructor(decl);
			if (cname == "DImport" || cname == "DUsing" || cname == "DPackage") {
				importDecls.push(decl);
			}
		}
		if (importDecls.length > 0) {
			try {
				var expr = Tools.moduleDeclsToExpr(importDecls, {isScriptedClass: false});
				interp.expr(expr);
			} catch(e:Dynamic) {
				trace("Error applying imports: " + e);
			}
		}
	}

	public static function registerRuleScriptedClass(typePath:String, classType:ScriptedClassType):ScriptedClassType return types[typePath] = classType;
	public static function getClass(typePath:String):ScriptedClass return cast types[typePath];
	public static function listScriptClasses():Array<String> return [for (key in types.keys()) key];

	public static function buildRuleScript(typePath:String, superInstance:Dynamic):RuleScript
	{
		if (buildBridge != null) 
			return buildBridge(typePath, superInstance);

		final type:ScriptedClassType = types[typePath] ?? ScriptedTypeUtil.resolveScript(typePath);
		final rulescript = new rulescript.RuleScript();
		rulescript.superInstance = superInstance;
		rulescript.scriptName = typePath;
		if (rulescript.interp is RuleScriptInterp)
			cast(rulescript.interp, RuleScriptInterp).skipNextRestore = true;

		if (type.isExpr) rulescript.execute(cast type);
		else buildScriptedClass(cast type, rulescript);
		return rulescript;
	}

	public static function buildScriptedClass(cl:ScriptedClass, rulescript:RuleScript):Void
	{
		rulescript.access.setVariable('new', () -> {});

		var list = [];
		var currentClass:ScriptedClass = cl;
		while (currentClass != null) {
			list.insert(0, currentClass);
			currentClass = (currentClass.superClass is ScriptedClass) ? cast currentClass.superClass : null;
		}

		var superFields:Array<String> = [];
		if (cl.nativeClass != null) {
			var nativeFields = Type.getInstanceFields(cast cl.nativeClass);
			if (nativeFields != null) for (f in nativeFields) superFields.push(f);
		}
		
		var currentSuper = cl.superClass;
		while (currentSuper != null && currentSuper is ScriptedClass) {
			final sc:ScriptedClass = cast currentSuper;
			if (sc.impl?.fields != null) {
				for (f in sc.impl.fields)
					if (!superFields.contains(f.name)) superFields.push(f.name);
			}
			currentSuper = sc.superClass;
		}

		if (cl.impl?.fields != null) {
			for (field in cl.impl.fields) {
				if (field.name == "new" || field.access.contains(AStatic)) 
					continue;

				final isOverride = field.access.contains(AOverride);
				final parentHasField = superFields.contains(field.name);
				if (isOverride && !parentHasField)
					throw new haxe.Exception('Field "${field.name}" is declared as override, but overrides nothing in class "${cl.className}".');
				else if (!isOverride && parentHasField)
					throw new haxe.Exception('Method "${field.name}" overrides a parent field, but is missing the "override" keyword in class "${cl.className}".');
			}
		}

		var exprList:Array<Expr> = [];
		for (targetClass in list) {
			if (rulescript.interp is RuleScriptInterp)
				applyImportsFromDecls(cast rulescript.interp, targetClass.module.sharedDecls);

			final exprs = Tools.moduleDeclsToExpr(targetClass.module.sharedDecls, {
				classImpl: targetClass.impl,
				isScriptedClass: true,
				fieldFilter: f -> !f.access.contains(AStatic)
			});

			final subExprs:Array<Expr> = switch (exprs.getExpr()) {
				case EBlock(e): e;
				case e: [exprs];
			}
			for (expr in subExprs) exprList.push(expr);
		}

		rulescript.execute(EBlock(exprList).toExpr());
	}
}