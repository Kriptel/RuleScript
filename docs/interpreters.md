# Interpreters

### Table of Contents:
- [Neo Interpreter](#neo-interpreter) (IN DEVELOPMENT)
- [Bytecode Interpreter](#bytecode-interpreter)
- [RuleScript Interpreter](#rulescript-interpreter)

---

### Neo Interpreter
> [!WARNING]
> Neo interpreter is currently under development. 
> Its functionality is limited compared to other interpreters.

> [!NOTE]
> Neo interpreter is a successor to the previous bytecode interpreter, fixing its stability, performance, and readability problems.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.NeoInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---

### Bytecode Interpreter 
> [!WARNING]
> This is extremely broken and isn't recommended to be used. 
> [Neo Interpreter](#neo-interpreter) is the replacement for this, and is currently being written from scratch.
>
> **!!! THIS WILL BE REPLACED WITH THE [NEO INTERPRETER](#neo-interpreter) !!!**

> [!NOTE]
> Optimizes and converts `hscript.Expr` to bytecode, distributes objects into buffers. Works much faster than RuleScriptInterp.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.BytecodeInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---

### Rulescript Interpreter
> [!NOTE]
> This is a stable and reliable interpreter, it extends from `HScript`'s interpreter, it is efficient and works well. **However**, it's recommended to use the [Neo Interpreter](#neo-interpreter) once it's finished.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.RuleScriptInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---