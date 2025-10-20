# Abstracts in Scripts

`RuleScriptAbstracts.txt` allows you to use abstracts in your code. 

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
