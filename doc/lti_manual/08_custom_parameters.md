# Custom Parameters
Custom parameters (AKA custom fields) add launch parameters specific to a tool, a tool placement, or a resource link. These can be static values, or values that provide specific information which are expanded at launch time by the variable expander. See the [public docs](https://canvas.instructure.com/doc/api/file.tools_variable_substitutions.html).

Internal Instructure-owned LTI 1.1 tools can use `BulkToolUpdater` in `instructure_misc_plugin` to bulk-update custom fields or tool settings on existing tools. Run `DataFixup::BulkToolUpdater.help` or talk to the Interop team. (LTI 1.3 tools can be updated simply by modifying the Developer Key, which will update all tool installations.)
