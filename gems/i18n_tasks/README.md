# i18n tasks

## Pre-compiled JS assets

The tasks will fail if any single JS file contains more than one `I18n()` scope (usually acquired by requiring `'i18n!some_scope'`), this is because the processors expect each JS source file to use only one scope.

However, an exception can be made for JS assets that are "pre-compiled", e.g, using the require.js optimizer or any file concatenator. In this case, we can instruct the tasks to treat these files in a special manner by writing a special header on the **very first line of the file**:

    /* canvas_precompiled_asset: TARGET */

With this header in place, the tasks will scan such sources for all modules, and treat each module as a "separate" file just as if you actually broke down the source file into separate ones, one for each module.

Current supported targets are: `amd`.