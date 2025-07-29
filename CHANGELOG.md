# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Regular expressions.
- Module fields.
- `cast` expression.
- `untyped __rulescript__interpType` expression.
- `untyped` expression.
- `:forceOverride` metadata.
- ScriptedAbstract.
- ScriptedTypeUtil.
- Typedefs.
- `final` variables.
- Bytecode interpreter.
- RuleScriptAccess (see [#20](https://github.com/Kriptel/RuleScript/pull/20)).
- RuleScriptedClass can be extended two or more times.
- Type parameters parse.
- Enum parse to HxParser.
- Enum constructors (with and without arguments).
- setParameters function to HxParser.
- rulescript.parsers.HxParser.HxParserParams type.
- `__rulescript_strict` field adds to classes with the RuleScriptedClass interface.
- `:alias` metadata for abstracts.
- `getVariables` function to RuleScriptedClass.
- ScriptedClass, ScriptedInstance, Access types in rulescript.scriptedClass.RuleScriptedClass module.
- Abstract parse to HxParser.
- Type path.
- `list` static variable to Abstracts.
- `allowPackage`, `allowImport`, `allowUsing` variables to HxParser.

### Fixed
- Error when calling methods with 9 or more arguments in Hashlink target (now limit is 12 arguments).
- Some compilation errors in AbstractMacro.
- Abstracts resolve.
- Fixed missing static modifier for the HxParser.defaultPreprocesorValues ​​field.

### Changed
- Improved `RuleScriptAbstracts.txt`: Added ignore and comment syntax, and empty lines are automatically ignored.
- `rulescript.Abstracts` moved to `rulescript.types.Abstracts`.
- `rulescript.RuleScriptProperty` moved to `rulescript.types.Property`.
- `rulescript.RuleScriptProperty.Property` moved to `rulescript.types.Property.PropertyAccess`.
- Reworked AbstractMacro.
- Renamed rulescript.macro.RuleScriptedClass to rulescript.macro.RuleScriptedClassMacro.

### Removed
- `rulescript.Abstracts.AbstractDecl` typedef.
- `rulescript.Parser` typedef.
- `rulescript.HxParser` typedef.
- Converter macro.

### Deprecated
- rulescript.RulescriptInterp.
- HScriptParserPlus.

## [0.2.0] 2024.12.07

### Added
- `defaultPreprocesorValues` static variable to HxParser.
- `preprocesorValues` variable to HxParser.
- `defaultImports` static variable to RuleScript.
- `:ignoreFields` metadata.
- Custom Std and Math for Hashlink target.

### Fixed
- Error with super field set.
- Error with scripted methods in Hashlink target.
- Error with dollar symbol in string interplation.
- Some bugs with Int in enum abstracts.
- Map Key => value iterator in Hashlink target.

## [0.2.0-rc] 2024.10.25

### Fixed
- Fixed bug with type aliases in RuleScriptedClass.
- Typos in `README.md`.

## [0.2.0-beta] 2024.10.14

### Added
- RuleScripted Classes.
- RuleScriptedClassUtil.
- RuleScriptedClass interface.
- `this` in script.
- Script Properties.
- `hasErrorHandler` variable to RuleScript and RuleScriptInterp.
- `errorHandler` variable to RuleScript and RuleScriptInterp.
- Key => value iterator.
- Rest.
- `superInstance` variable to RuleScriptInterp.
- `onMeta` callback in RuleScriptInterp.
- Classes (MODULE mode only).
- HxParserMode.
- `moduleDeclsToExpr` function to HScriptParserPlus.
- `buildModuleDecl` function to ExprMacro.

### Changed
- New String Interpolation.
- Resolve now can find local classes from modules.
- Parser and HxParser was moved to rulescript.parsers package.

### Deprecated
- rulescript.Parser and rulescript.HxParser.
- rulescript.parsers.HxParser.HScriptParserPlus.moduleDeclsToExpr.

### Fixed
- Fixed bug when AbstractMacro can't find abstracts in a module other than it's name.
- Fixed `using` error on Haxe Interpreter.
- Fixed compile error on non-cpp targets.
- Improve `using` resolve function.

## [0.1.1] - 2024-09-15

### Fixed
- Fixed bug when converted abstracts were not generated.
- Fixed bug when static inline vars in converted abstracts were not accessible.

## [0.1.0] - 2024-09-07

### Added

- Abstract statics support.
- Date and Datetools defaults for RuleScriptInterp.

### Fixed

- Fixed bug when code ignored properties.

## [0.0.1] - 2024-09-06

Initial Release.

[unreleased]: https://github.com/Kriptel/RuleScript/compare/0.2.0...master
[0.2.0]: https://github.com/Kriptel/RuleScript/compare/0.2.0-rc...0.2.0
[0.2.0-rc]: https://github.com/Kriptel/RuleScript/compare/285a17e13b45c9b04fcf12c7590f369e39f119e3...0.2.0-rc
[0.2.0-beta]: https://github.com/Kriptel/RuleScript/compare/0.1.1...285a17e13b45c9b04fcf12c7590f369e39f119e3
[0.1.1]: https://github.com/Kriptel/RuleScript/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/Kriptel/RuleScript/compare/0.0.1...0.1.0
[0.0.1]: https://github.com/Kriptel/RuleScript/releases/tag/0.0.1