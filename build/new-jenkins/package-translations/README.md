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

You also need to add a `git add` line for your sub-package to `sync-strings.sh` so the output of `yarn installTranslations` (if there is any in your sub-package)
gets committed by the build.

## Debugging

- You can make changes to the scripts here, git add, commit, and push to gerrit.
- Then visit the jenkins package-translations build page
- The GERRIT_SPEC is `refs/changes/59/314059/1` where `314059` is your gerrit's id and `1` is the patchset number.
- Click _Build_ button to start the build. (The last time I did this I was commenting out the `git commit` code in the scripts so I could
  run it over and over.)
