# Canvas Rich Content Editor

The Canvas LMS Rich Content Editor extracted in it's own npm package for use
across multiple services. This npm module is used in pair with a running
`canvas-rce-api` microservice.

You need a running instance of the `canvas-rce-api` in order to utilize
the `canvas-rce` npm module, but you do not need that instance in order to
do development on `canvas-rce`. (see [docs/development.md](docs/development.md))

The first customer of the `canvas-rce` was the `canvas-lms` LMS so documentation
and references throughout documentation might reflect and assume the use of
`canvas-lms`.

# Install and setup

As a published npm module, you can add canvas-rce to your node project by doing
the following:

```bash
npm install canvas-rce --save
```

Please reference the [canvas-lms use of canvas-rce](https://github.com/instructure/canvas-lms/tree/stable/app/jsx/shared/rce)
to get an idea on how to incorporate it into your project. Pay
special attention to the `RichContentEditor.js` and `serviceRCELoader.js`.

## Polyfills
This project makes use of modern JavaScript APIs like Promise, Object.assign,
Array.prototype.includes, etc. which are present in modern
browsers but may not be present in old browsers like IE 11. In order to not
send unnesicarily large and duplicated code bundles to the browser, consumers
are expected to have already globally polyfilled those APIs.
Canvas already does this but if you need suggestions for how to this in your
own app, you can just put this in your html above the script that includes
canvas-rce:
```
<script src="https://cdn.polyfill.io/v2/polyfill.min.js?rum=0"></script>
```
(See: https://polyfill.io/v2/docs/ for more info)

# Development

## Upgrading TinyMCE

### Language Packs

Translations for TinyMCE are not shipped with the `tinymce` npm package. When
upgrading to a new version be sure to download the latest language packs. Visit
https://www.tinymce.com/download/language-packages/ and select all languages. It
is easier to just download all and only commit the changes to existing files
than try to only select the locales currently used. Download the file and
extract all of th `.js` files to `./src/rce/languages/`. After commiting the
changed locale files you can run `git clean -f ./src/rce/languages/` to remove
the untracked language files.

## Adding Languages

### TinyMCE Language Pack

Download the new TinyMCE language pack by visiting
https://www.tinymce.com/download/language-packages/ and select the language.
Copy the JavaScript file to `./src/rce/languages/`.

### Locale Code Mappings

Since different projects have a hard time agreeing on locale code format, a file
mapping Canvas locale codes to TinyMCE locale codes needs to be updated. This is
found in `./src/rce/editorLanguage.js`.

### Recognized Languages

The `./src/rce/normalizeLocale.js` file includes a list of valid locales. The
new locale should be added here.

### Locale Module

A locale module should be added for each new locale, with a name matching the
Canvas locale code. This file adds the translations to the `canvas-rce`
formatMessage namespace, and loads the TinyMCE translations.

#### Example

```js
import formatMessage from "../format-message";
import locale from "../../locales/locale-code.json";
import "../rce/languages/tinymce_locale";
formatMessage.addLocale({ "locale-code": locale });
```
