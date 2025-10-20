Table of Contents:
- [Neo Interpreter](#neo-interpreter)
- [Bytecode Interpreter](#bytecode-interpreter)
- [RuleScript Interpreter](#rulescript-interpreter)

### Neo Interpreter
> [!WARNING]
> Neo interpreter is currently under development. 
> Its functionality is limited compared to other interpreters.

Neo interpreter is a successor to the previous bytecode interpreter, fixing its stability, performance, and readability problems.

```haxe
script = new RuleScript(new rulescript.interps.NeoInterp());

script.execute('trace("Hello World")'); // Returns: "Hello World"
```

### Bytecode Interpreter 
> [!NOTE]
> Optimizes and converts `hscript.Expr` to bytecode, distributes objects into buffers. Works much faster than RuleScriptInterp.

```haxe
script = new RuleScript(new rulescript.interps.BytecodeInterp());

script.execute('trace("Hello World")'); // Returns: "Hello World"
```

### RuleScript Interpreter
> [!NOTE]
> This is 