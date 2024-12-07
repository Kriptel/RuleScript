# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
[0.2.0-rc]: https://github.com/Kriptel/RuleScript/compare/285a17e13b45c9b04fcf12c7590f369e39f119e3...0.2.0-rc
[0.2.0-beta]: https://github.com/Kriptel/RuleScript/compare/0.1.1...285a17e13b45c9b04fcf12c7590f369e39f119e3
[0.1.1]: https://github.com/Kriptel/RuleScript/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/Kriptel/RuleScript/compare/0.0.1...0.1.0
[0.0.1]: https://github.com/Kriptel/RuleScript/releases/tag/0.0.1
