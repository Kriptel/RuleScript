# RuleScript

Hscript addon with script classes, imports, usings, properties, string interpolation and more.

## Features:

- [Package](#package)
- [Import](#import)
	- [Alias](#import-with-alias)
	- [Static field](#static-field-import)
- [Using](#using)
- [Property](#property)
- [String interpolation](#string-interpolation)
- [Script Class](#rulescriptedclass)
- [Abstracts in script](#abstracts-in-script)
- [Key => value Iterator](#key--value-iterator)
- [`??` and `??=` operators](#-and--operators)

### Package
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

### Static field import
```haxe
import Reflect.getProperty;

var a = {
	"hello":"world"
};

return getProperty(a,"hello");
```

### Using
```haxe
using Reflect;

var a = {
  "Hello":"World"
};
trace(a.getProperty("Hello")); // World
```

### Property
```haxe
var _a = 'Hello World';

var a(get,set):String;

function get_a():String
	return _a;

function set_a(v:String):String
	return _a = v;

trace(a); // Hello World
```

### String interpolation
RuleScript supports [String Interpolation](https://haxe.org/manual/lf-string-interpolation.html), but you can only use identifiers, double quotes string, calls without arguments and `+` operator.
```haxe
var a = 'Hello';
trace('RuleScript: $a World'); // RuleScript: Hello World
```
```haxe
var a = {
    a:'RuleScript',
    b: () -> 'Hello',
    c: (a) -> a ? 'World' : '';
};
        
trace('${a.a}: ${a.b() + ' ' + a.c(true)}'); // RuleScript: Hello World
```

### RuleScriptedClass
Rulescript supports scripted classes, they can have a strict and non-strict constructor. 

Script :
```haxe
class ScriptedClass extends test.ScriptedClassTest
{
	public function new(customArg:Int,arg1:String)
	{
		trace('Constructor.pre: $customArg, $arg1');
		
		super('Super Arg');

		trace('Constructor.post: $customArg, $arg1');	
	}

	override public function info()
	{
		return 'Scripted class, super info: ${super.info()}';
	}
}
```
Source :
```haxe
class ScriptedClassTest implements RuleScriptedClass extends SrcClass {}
```

See [`Main.hx`](./test/src/Main.hx#l267), [`ScriptedClassTest.hx`](./test/src/test/ScriptedClassTest.hx), [`ScriptedClass`](./test/scripts/haxe/ScriptedClass.rhx).

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

### Key => value iterator
```haxe
var map = [
	'RuleScript' => 'Hello World',
];

for(key => value in map){
	trace('$key: $value'); // RuleScript:'Hello World'
}
```

### `??` and `??=` operators
```haxe
trace(null ?? 'Hello World'); // Hello World

var a = 'hello';

a ??= 'world';
trace(a); // hello

a = null;
a ??= 'world';
trace(a) // world
```
# Limitations

- Script `using` callback supports max number of arguments is 8.
- [Wildcard imports](https://haxe.org/manual/type-system-import.html#wildcard-import) don't support.
- AbstractMacro ports only static fields

# To Do
- Lua Parser
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
