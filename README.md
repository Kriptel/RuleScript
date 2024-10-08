# RuleScript

Hscript addon with imports, usings, string interpolation and more.

## Features:

### Package
package keyword (optional).
```haxe
package scripts.hello.world;
```
### Import
```haxe
import haxe.ds.StringMap;

var map = new StringMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```
### Import with alias
you can use `as` or `in` keywords alias.
```haxe
import haxe.ds.StringMap as StrMap;

var map = new StrMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```
```haxe
import haxe.ds.StringMap in StrMap;

var map = new StrMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```

### Using
```haxe
using Reflect;

var a = {
  "Hello":"World"
};
trace(a.getProperty("Hello")); // World
```

### String interpolation (Experimental)
RuleScript supports [String Interpolation](https://haxe.org/manual/lf-string-interpolation.html), but you can only use identifiers, double quotes string, calls without arguments and `+` operator.
```haxe
var a = 'Hello';
trace('RuleScript: $a World'); // RuleScript: Hello World
```
```haxe
var a = {
    a:'RuleScript',
    b: () -> 'Hello',
    c:'World'
};
        
trace('${a.a}: ${a.b() + " " + a.c}'); // RuleScript: Hello World
```

### Abstracts in script

`RuleScriptAbstracts.txt` in any classpath :
```
test.HelloWorldAbstract
```

test/HelloWorldAbstract.hx :
```haxe
abstract HelloWorldAbstract(String) from String to String
{
	public static function rulescriptPrint():HelloWorldAbstract
		return 'Hello World';
}
```
Script :
```haxe
import test.HelloWorldAbstract;

trace(HelloWorldAbstract.rulescriptPrint()); // 'Hello World'
```
More templates in [`test/src/Main.hx`](https://github.com/Kriptel/RuleScript/blob/master/test/src/Main.hx).

# Limitations

- [String interpolations](https://haxe.org/manual/lf-string-interpolation.html) don't support many functions
- Script `using` callback supports max number of arguments is 8.
- [Wildcard imports](https://haxe.org/manual/type-system-import.html#wildcard-import) don't support.
- AbstractMacro ports only static fields

# To Do
- Lua Parser
- Improve String Interpolation
- Improve hscript module parser

# Install

1. Installing lib: 
- haxelib version
    - Haxelib : `haxelib install rulescript`
    - Hmm : `hmm haxelib rulescript`
- github version

    - Haxelib : `haxelib git rulescript https://github.com/Kriptel/RuleScript.git`
    - Hmm : `hmm git rulescript https://github.com/Kriptel/RuleScript.git`
- github version (dev)

    - Haxelib : `haxelib git rulescript https://github.com/Kriptel/RuleScript.git dev`
    - Hmm : `hmm git rulescript https://github.com/Kriptel/RuleScript.git dev`
2. Adding lib to your project:
    
    Hxml :
    ```hxml
    -lib rulescript
    ```
    
    Lime/OpenFL :
    ```xml
    <haxelib name="rulescript"/>
    ```
