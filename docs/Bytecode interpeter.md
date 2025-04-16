# Bytecode interpeter

Байт-код интерпретатор конвертирует hscript.Expr в байты, понятные для интерпретатора. Этот метод интерпретации использует меньше динамики, что делает его очень быстрым.

Для упрощения работы эти байты представлены в виде `Array<Command>`.

При вызове execute `hscript.Expr` передаётся в конвертатор, который по сути является AST, который оптимизирует и старается минимизировать в операторах динамику. Для типов String, Float, Dynamic и Class выделены отдельные буферы, поэтому байт-код сохранять или передавать в другой интерпретатор небезопасно.

## Examples
- [Basic use](#basic-use)

### Basic use

```haxe
import rulescript.BytecodeInterp;

function main()
{
	// With rulescript.Rulescript
	var script = new rulescript.RuleScript(new BytecodeInterp());
	trace(script.execute('return "Hello world"')); // Hello world 

	// Without rulescript.Rulescript
	var parser = new rulescript.parsers.HxParser();
	var interp = new BytecodeInterp();
	trace(interp.execute(parser.parse('return "Hello world"'))); // Hello world 
}
```

### Use as default interpreter

```haxe
import rulescript.RuleScript;
import rulescript.BytecodeInterp;

function main()
{
	Rulescript.createInterp = () -> new BytecodeInterp();

	var script = new RuleScript();
	trace(script.interp is BytecodeInterp); // true
}
```

## Errors

### Exception: CONST.

Ошибка происходит обычно из-за выхода `pos` за пределы буфера. Это ошибка со стороны интерпретатора или конвертера.

### Exception: Null access.

Ошибка происходит, когда пытаетесь получить доступ к полю у нулевого объекта.

### Exception: Unknown type.

Ошибка происходит, когда вы пытаетесь использовать неподдерживаемый тип или.

### Exception: Unknown operator `op`.

Ошибка происходит, когда не существует оператора `op`.

### Exception: Invalid operator `op`

Ошибка происходит, когда не существует унарного оператора `op`

### Exception: Invalid assign.

Ошибка происходит, когда вы неправильно используете оператор `=`.

### Exception: Unsupported expression

Ошибка происходит, когда вы используете неподдерживаемый вид Expr.