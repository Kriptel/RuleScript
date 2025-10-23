# RuleScript

[Hscript](https://github.com/HaxeFoundation/hscript) addon featuring script classes, imports, usings, properties, string interpolation and more.

## Features

### Basic
- [Package](./docs/basic.md#package)
- [Import](./docs/basic.md#import)
- [Wildcard Import](./docs/basic.md#wildcard-import)
- [Import with Alias](./docs/basic.md#import-with-alias)
- [Static Field Import](./docs/basic.md#static-field-import)
- [Using](./docs/basic.md#using)
- [Property Access](./docs/basic.md#property)
- [Type Path](./docs/basic.md#type-path)
  
### Advanced
- [Abstracts](./docs/abstracts.md)
- [Interpreters](./docs/interpreters.md)
- [RuleScriptedClass](./docs/scripted-classes.md)
- [Scripted Classes](./docs/scripted-classes.md#rulescriptedclass)
- [String Interpolation](./docs/advanced.md#string-interpolation)
- [Regular Expressions](./docs/advanced.md#regular-expressions)
- [Typedefs](./docs/advanced.md#typedefs)
- [`??` and `??=` Operators](./docs/advanced.md#-and--operators)
- [Rest](./docs/advanced.md#rest)

### Other
- [Context](./docs/context.md)
- [Interpreters](./docs/interpreters.md)
- [HxParser Settings](./docs/advanced.md#hxparser-settings)
- [Limitations](#limitations)
- [Install](#install)

## Limitations

- Script `using` callbacks support a maximum of 8 arguments.
- AbstractMacro only supports `static` [abstract](https://haxe.org/manual/types-abstract-class.html) fields.

## Install

1. Installing the library: 
	- haxelib version

 		- Haxelib : `haxelib install rulescript`
		- Hmm : `hmm haxelib rulescript`
	- github version

		- Haxelib : `haxelib git rulescript https://github.com/Kriptel/RuleScript.git`
		- Hmm : `hmm git rulescript https://github.com/Kriptel/RuleScript.git`
	- github version (dev) <br>
		 ```WARNING ⚠️ Dev version of RuleScript requires [git version of hscript](https://github.com/HaxeFoundation/hscript)```
    	- Haxelib : `haxelib git rulescript https://github.com/Kriptel/RuleScript.git dev`
    	- Hmm : `hmm git rulescript https://github.com/Kriptel/RuleScript.git dev`
2. Adding the library to your project:
    
    Hxml :
    ```hxml
    -lib rulescript
    ```
    
    Lime/OpenFL :
    ```xml
    <haxelib name="rulescript"/>
    ```

---

Full list of contributors [here](https://github.com/Kriptel/RuleScript/graphs/contributors).