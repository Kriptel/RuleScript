# RuleScripted Class
> [!NOTE]
> RuleScript also supports scripted classes; these can have strict and non-strict constructors.

## Metadata
- `:noBuild` **(Type Metadata)** Stops the `RuleScriptedClassMacro` from building the **type**.
- `:ignoreFields` **(Type Metadata; a1:`Array<String>`)**
- `:forceOverride` **(Type Metadata; a1:`Array<String>`)** // **(Field Metadata)**
- `:strictScriptedConstructor`/`:strictConstructor` **(Type Metadata)**, Enforces a **`strict`** scripted constructor...
- `:strictConstructor` **(Type Metadata)**, Enforces a **`strict`** constructor...


## Script Example
### Script:
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
---
### Source Code:
```haxe
class ScriptedClassTest implements RuleScriptedClass extends SrcClass {}
```

---

Also, see [`Main.hx`](../test/src/Main.hx#l53), [`ScriptedClassTest.hx`](../test/src/example/ScriptedClassTest.hx), and/or [`ScriptedClass`](../test/scripts/scriptedClass/ScriptedClass.rhx).