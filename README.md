# RuleScript

Hscript addon with imports, usings, string interpolation and more.

## Features:

### Package :
package keyword (optional).
```haxe
package scripts.hello.world;
```
### Import :
```haxe
import haxe.ds.StringMap;

var map = new StringMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```
### Import with alias:
you can use `as` or `in` keywords alias.
```haxe
import haxe.ds.StringMap as StrMap;

var map = new StrMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```
You also can use `in` keyword.
```haxe
import haxe.ds.StringMap in StrMap;

var map = new StrMap();
map.set("Hello","World");
trace(map.get("Hello")); // World
```

### Using:
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
return 'RuleScript: $a World'; // RuleScript: Hello World
```

More templates in `test/src/Main.hx`.
# Limitations

- String interpolations don't support many functions.
- Script `using` callback supports max number of arguments is 8.
- [Wildcard imports](https://haxe.org/manual/type-system-import.html#wildcard-import) don't support.

# To Do:
- Lua Parser
- Importing abstract classes in scripts
- Improve String Interpolation
- Improve hscript module parser

# Install

1. Installing lib : 
- Haxelib : `haxelib git rulescript https://github.com/Kriptel/RuleScript.git`
- Hmm : `hmm git rulescript https://github.com/Kriptel/RuleScript.git`
2. Adding lib to your project :
- Hxml :
```hxml
-lib rulescript
```
- Lime/OpenFL :
```xml
<haxelib name="rulescript"/>
```
