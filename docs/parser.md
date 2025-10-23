# Parser

Documentation for parsers...

## Settings

> [!NOTE]
> The parser can be configured, some functions can be disabled or enabled.<br>
> Use the `setParameters` function to configure the parser.

### List of parameters:

- `allowJSON` - **Whether to allow `JSON`s or not...**
- `allowMetadata` - **Whether to allow `Metadata` or not...** 
- `allowTypes` - **Whether to allow `Types` or not...**  
- `allowPackage` - **Whether to allow `Package`'s or not...** 
- `allowImport` - **Whether to allow `Importing` or not...** 
- `allowUsing` - **Whether to allow `Using` or not...** 
- `allowStringInterpolation` - **Whether to allow `String Interpolation` or not...** 
- `allowTypePath`  - Whether to allow `Type Path` or not... 

## Parser modes:
> [!NOTE]
> To **set** the parser **mode**, you'll need to:
> ```haxe
> parser.mode = DEFAULT; // Default
> parser.mode = MODULE; // Modules
> ```

- `HxParserMode.DEFAULT` - Used for parsing **Normal** scripts...
- `HxParserMode.MODULE` - Used for parsing, **Modules**/**Classes**...

<br>

---