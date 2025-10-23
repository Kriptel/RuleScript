# RuleScripted Class
> [!NOTE]
> RuleScript also supports scripted classes; these can have strict and non-strict constructors.
---
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

Also, see [`Main.hx`](../test/src/Main.hx#l53), [`ScriptedClassTest.hx`](../test/src/example/ScriptedClassTest.hx), [`ScriptedClass`](../test/scripts/scriptedClass/ScriptedClass.rhx).