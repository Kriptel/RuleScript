# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Super instance var to RuleScriptInterp
- Classes (MODULE mode only)
- HxParserMode
- `moduleDeclsToExpr` function to HScriptParserPlus
- `buildModuleDecl` function to ExprMacro

### Fixed
- Fixed `using` error on Haxe Interpreter
- Fixed compile error on non-cpp targets
- Improve `using` resolve function 

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
