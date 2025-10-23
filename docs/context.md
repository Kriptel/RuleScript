# Context

> [!NOTE]
> `Context` is a type store that helps avoid recompiling the same types, it is also used for storing shared and static variables for scripts using the same `Context` instance.

---

[`VARIABLE`] : `types` - Stores all previously `defined` types.<br>
[`VARIABLE`] : `publicVariables` - **Public** variables, everything in this array is either added using the meta `@:contextValue('public')`, or the keyword `public`.
<br>
[`VARIABLE`] : `staticVariables` - **Static** variables, everything in this array is either added using the meta `@:contextValue('static')`, or the keyword `static`.

---

[`VOID`] : `reset` Resets `types`, `staticVariables`, and `publicVariables`.<br>
[`VOID`] : `resetVariables` - Resets `publicVariables` and `staticVariables`.<br>
[`VOID`] : `resolveType` - Checks if the type has already been processed and pushed to the `types` array, if it has i'll use that instead of processing it, this helps speed things up!

---


<!-- not orbl was here -->