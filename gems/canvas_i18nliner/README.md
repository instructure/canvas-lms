# canvas_i18nliner

## i18nliner, canvas style

this will replace the i18n_tasks and i18n_extraction gems

`.i18nrc` files must glob for files to be included through the `files` property:

```json
{
  "files": [
    {
      "pattern": "**/*.js",
      "processor": "js"
    },
    {
      "pattern": "**/*.{hbs,handlebars}",
      "processor": "hbs"
    }
  ]
}
```

`.i18nrc` files can include other files that may in turn specify more files:

```json
{
  "include": [ "relative/path/to/.i18nrc" ]
}
```

`.i18nignore` files can exclude files from processing relative to where they
are defined (similar to `.gitignore`):

```json
// file: app/.i18nignore
foo 
bar/**/*.js
```

The above ignore file will exclude `app/foo` and `app/bar/**/*.js`.

**Where to place ignore lists?**

The scanner will always look for an `.i18nignore` adjacent to `.i18nrc`, but it
will also discover and use any `.i18nignore` file found between the root
and the target file:

```
app
├── .i18nignore
└── a
    ├── .i18nignore
    └── b
        └── c
```

A file under `app/a/b/c/` is subject to exclusion according to rules found in 
both `app/.i18nignore` and `app/a/.i18nignore`.