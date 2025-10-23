# Context

`Context` is a type store that helps avoid recompiling the same types, it is also used for storing shared and static variables for scripts using the same `Context` instance.

---

`types` - Stores all previously `defined` types.

`publicVariables` - Public Variables, everything in this array is either added using the meta `@:contextValue('public')`.

`staticVariables` - Static Variables, everything in this array is either added using the meta `@:contextValue('static')`.

`reset` Resets `types`, `staticVariables`, and `publicVariables`.

`resetVariables` - Resets `publicVariables` and `staticVariables`.

`resolveType` - Checks if the type has already been processed and pushed to the `types` array, if it has i'll use that instead of processing it, this helps speed things up!

---