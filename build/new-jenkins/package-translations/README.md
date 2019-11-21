# Translations

This directory contains scripts to handle translations for the packages/
directory.

These scripts are based in part on things done in the Quizzes project.

## Assumptions

In order for a package to be translated properly, it must contain an `i18n:extract`
command in its package.json file.

This command should essentially do something similar to:

```sh
format-message extract $(find src -name \"*.js\") -g underscored_crc32 -o locales/en.json
```

The end result should be an `en.json` file containing the english strings extracted from the package inside a `locales` directory at the root of the package.
