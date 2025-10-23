# Context

> [!NOTE]
> `Context` is a type store that helps avoid recompiling the same types, it is also used for storing shared and static variables for scripts using the same `Context` instance.

---

### Variables

> [!WARNING]
> `public`/`static` keywords are only converted to `@:contextValue("static" || "public")` in the `DEFAULT` parser mode.<br>
> See: [Parser Modes](./parser.md#parser-modes)

- `types` - Stores all previously `defined` types.

- `publicVariables` - **Public** variables, everything in this array is either added using the meta `@:contextValue('public')`, or the keyword `public`.

- `staticVariables` - **Static** variables, everything in this array is either added using the meta `@:contextValue('static')`, or the keyword `static`.

---

`reset` Resets `types`, `staticVariables`, and `publicVariables`.

`resetVariables` - Resets `publicVariables` and `staticVariables`.

`resolveType` - Checks if the type has already been processed and pushed to the `types` array, if it has i'll use that instead of processing it, this helps speed things up!

---


<!-- not orbl was here -->