# Advanced Features

### Table of Contents:
- [String interpolation](#string-interpolation)<!-- weird fix, i guess.... -->
- [Regular expressions](#regular-expressions)
- [Typedefs](#typedefs)
- [`??` and `??=` operators](#-and--operators)
- [Rest](#rest)

---

### String interpolation
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

---

### Regular expressions
```haxe
~/haxe/i;
```

---

### Typedefs

> [!NOTE]
> Allows you to set the type path to any value. Has a higher resolve priority than classes, abstracts, or enums, but lower than `resolveScript`.

```haxe
Typedefs.register('hello.world.HxParser', HxParser);

var script = new RuleScript();
trace(script.execute('hello.world.HxParser') == HxParser); // true
```


---

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

---

### Rest
```haxe
var f = function(hello:String, ...rest:Dynamic)
{
	return '$hello: ' + rest.join(' ');
}

trace(f('Rulescript','Hello','World','!')); // Rulescript: Hello World !

trace(f('Rulescript',...['Hello','World','!'])); // Rulescript: Hello World !
```

---
<br>
<div align="center">

[↑ To The Top ↑](#advanced-features)

</div>