# Abstracts

`RuleScriptAbstracts.txt` allows you to use abstracts in your code. 

---

## Metadata

### Alias `@:alias('docs.abstracts', true)`
> [!NOTE]
> Instead of using the original path, "`example.TestAbstract`", you can use the alias path "`hello.TestAbstract`" inside scripts.
> 
> For Example:
> ```haxe
> package example;
>
> @:alias('hello.TestAbstract', true)
> abstract TestAbstract(Test) from Test to Test {
>   public function new() : Void {}
> }
> ```
> script:
> ```haxe
> new hello.TestAbstract(); // is the equivalent of example.TestAbstract
> ```

---

### Ignore Field `@:ignoreField`
> [!NOTE]
> whether to ignore a field or not...
---


### Here's an example:
```txt
test.HelloWorldAbstract
example.TestAbstract
```

---

### **`test/HelloWorldAbstract.hx`** (`SOURCE`): 
```haxe
abstract HelloWorldAbstract(String) from String to String
{
    public static function rulescriptPrint():HelloWorldAbstract
    {
        return 'Hello World';
    }
}
```

---

### Script:
```haxe
import test.HelloWorldAbstract;

trace(HelloWorldAbstract.rulescriptPrint()); // Hello World
```
---

More templates can be found in [`test/src/Main.hx`](../test/src/Main.hx).
