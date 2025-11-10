# RuleScripted Class
> [!NOTE]
> RuleScript also supports scripted classes, which can have either strict or non-strict constructors.

## Metadata
- `:noBuild` **(Type Metadata)** Stops the `RuleScriptedClassMacro` from building the **type**.
- `:ignoreFields` **(Type Metadata; a1:`Array<String>`)**
- `:forceOverride` **(Type Metadata; a1:`Array<String>`)** // **(Field Metadata)**
- `:strictScriptedConstructor`/`:strictConstructor` **(Type Metadata)** Enforces a **strict** scripted constructor.


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

See also: [`Main.hx`](../test/src/Main.hx#l53), [`ScriptedClassTest.hx`](../test/src/example/ScriptedClassTest.hx), and/or [`ScriptedClass`](../test/scripts/scriptedClass/ScriptedClass.rhx).

<br>
<div align="center">

[↑ To The Top ↑](#rulescripted-class)

</div>