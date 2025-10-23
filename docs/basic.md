# Basic Features

### Table of Contents:
- [Package](#package)<!-- weird fix, i guess.... -->
- [Import](#import)
- [Wildcard Import](#wildcard-import)
- [Import with alias](#import-with-alias)
- [Static field import](#static-field-import)
- [Using](#using)
- [Property](#property)
- [Type path](#type-path)

---

### Package
```haxe
package scripts.hello.world;
```
---

### Import
```haxe
import haxe.ds.StringMap;

var map = new StringMap();
map.set("Hello", "World");
trace(map.get("Hello")); // World
```

---

### Wildcard Import

> [!WARNING]
> **!!! This is still experimental !!!**

```haxe
import haxe.ds.*;

new StringMap().set("Hello","World");
new ObjectMap().set({hello: world}, 123);
new IntMap().set(123, "Hello World");
```

---

### Import with alias

> [!NOTE]
> Supports both the `as` and `in` aliases.

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

---

### Static field import
```haxe
import Reflect.getProperty;

var a = {
	"hello":"world"
};

return getProperty(a,"hello");
```

---

### Using
```haxe
using Reflect;

var a = {
  "Hello":"World"
}
trace(a.getProperty("Hello")); // World
```

---

### Property
> [!NOTE]
> To set public or static variables you'll need to add the respective keyword, either `public` or `static`.<br>
> Public / Static Variables are save into the context, so you'll need to use the same context on another script, for you to be able to access its variables...

> [!WARNING]
> There is a known issue with public/static `get`/`set` variables not being able to find the `get_v1` & `get_v2` functions, even though they are there...<br>
> A work around for this would be defining the `get` & `set` functions before defining the variable... 
```haxe
var _a = 'Hello World';

var a(get,set):String;

function get_a():String
	return _a;

function set_a(v:String):String
	return _a = v;

trace(a); // Hello World
```

---

### Type path

> [!NOTE]
> Use any types without importing them using their type path.

```haxe
new haxe.ds.StringMap();
```

---
<br>
<div align="center">

[↑ To The Top ↑](#basic-features)

</div>