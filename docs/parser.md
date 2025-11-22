# Parser

## Settings

>[!IMPORTANT]
> You can configure the parser by enabling or disabling specific methods.<br>
> Use the `setParameters` method to adjust its behavior.

### List of parameters:

- `allowJSON` - **Whether to allow `JSONs` or not...**
- `allowMetadata` - **Whether to allow `Metadata` or not...** 
- `allowTypes` - **Whether to allow `Types` or not...**  
- `allowPackage` - **Whether to allow `Packages` or not...** 
- `allowImport` - **Whether to allow `Importing` or not...** 
- `allowUsing` - **Whether to allow `Using` or not...** 
- `allowStringInterpolation` - **Whether to allow `String Interpolation` or not...** 
- `allowTypePath` - **Whether to allow `Type Path` or not...**

## Parser modes:
> [!NOTE]
> To **set** the parser **mode**, you'll need to:
> ```haxe
> import rulescript.parsers.HxParser.HxParserMode;
>
> parser.mode = HxParserMode.DEFAULT; // Default
> parser.mode = HxParserMode.MODULE; // Modules
> ```

- `HxParserMode.DEFAULT` - Used for parsing **Normal** scripts...
- `HxParserMode.MODULE` - Used for parsing **Modules**/**Classes**...

<br>

---