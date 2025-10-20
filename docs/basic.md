### Package
```haxe
package scripts.hello.world;
```
### Import
```haxe
import haxe.ds.StringMap;

var map = new StringMap();
map.set("Hello", "World");
trace(map.get("Hello")); // World
```

### Wildcard import
```haxe
import haxe.ds.*;

new StringMap().set("Hello","World");
new ObjectMap().set({hello: world}, 123);
new IntMap().set(123, "Hello World");
```

### Import with alias
Supports both the `as` and `in` aliases.
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
}
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

### Type path

Use any types without importing them using their type path.

```haxe
sys.FileSystem;
```
```haxe
haxe.ds.StringMap;
```

