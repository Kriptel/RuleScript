# Interpreters

### Table of Contents:
- [Neo Interpreter](#neo-interpreter) (In Development)
- [Bytecode Interpreter](#bytecode-interpreter)
- [RuleScript Interpreter](#rulescript-interpreter)

---

### Neo Interpreter
> [!WARNING]
> [Neo Interpreter](#neo-interpreter) is currently under development. 
> Its functionality is currently limited compared to the other interpreters.

> [!NOTE]
> [Neo Interpreter](#neo-interpreter) is a successor to the previous bytecode interpreter, addressing the stability, performance, and readability issues of it's predecessor.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.NeoInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---

### Bytecode Interpreter 
> [!WARNING]
> This interpreter is extremely unstable and not recommended for use.
> [Neo Interpreter](#neo-interpreter) is the replacement for this, and is being rewritten from scratch.
>
> **!!! THIS WILL BE REPLACED WITH THE [NEO INTERPRETER](#neo-interpreter) !!!**

> [!NOTE]
> Optimizes and converts `hscript.Expr` to bytecode, distributes objects into buffers. It runs much faster than `RuleScriptInterp`.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.BytecodeInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---

### Rulescript Interpreter
> [!NOTE]
> This is a stable and reliable interpreter. It extends `HScript`'s interpreter and is efficient and dependable. However, it's **recommended** to switch to the [Neo Interpreter](#neo-interpreter) once development is **complete**.

```haxe
var script:RuleScript = new RuleScript(new rulescript.interps.RuleScriptInterp());
script.execute('trace("Hello World")'); // Returns: "Hello World"
```

---

<!-- orbl was here -->

<br>
<div align="center">

[↑ To The Top ↑](#interpreters)

</div>