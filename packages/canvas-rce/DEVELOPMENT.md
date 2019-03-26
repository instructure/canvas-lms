# Canvas Rich Content Editor - Development Guide

This guide is written for those planning to develop `canvas-rce` itself.  It will
guide you to getting things set up in a way that allows you to get off the
ground and get going quickly.

## Canvas RCE API

In order for all features of `canvas-rce` to work you'll also need a running copy
of `canvas-rce-api`.  You can get it from [canvas-rce-api](https://github.com/instructure/canvas-rce-api).  You'll want to follow the setup instructions for it in that repository as
they will be the most up to date.

## Developing

Here we'll talk about how to develop on `canvas-rce` without the use of Canvas.

You can get the "demo" development environment up and running by executing:

```shell

yarn dev

```

Then navigate to http://localhost:8080/demo.html and you will see the `canvas-rce` editor.
Any changes you make to files under `/src` will be reflected in this editor.

### Developing inside Canvas

Because this package lives in the Canvas packages workspace, you can make modifications to it without first needing to do a `yarn install` in Canvas.

You can start up the watch mode of this package by running `yarn build:watch` inside the `canvas-rce` directory.  Then in Canvas proper, you can run `yarn build:js:watch` and things generally work out.  If for some reason you get errors with the watch modes, you can fallback to the regular builds `yarn build:canvas` inside of `canvas-rce` and `yarn build:js` inside of Canvas. 

## Plugins

Canvas RCE specific plugins require using the [Canvas RCE API](#Canvas-RCE-API) normally, however
by default the demo environment provides a fake shim so that you can develop without actually
needing to use `canvas-rce-api` or Canvas.

There is a section available on the page that allows you to connect to a real `canvas-rce-api
`instance and to a real Canvas instance.  You can put a URL pointing to a running
`canvas-rce-api` instance as well as a JWT from Canvas.  You can get the JWT from Canvas by
going to any page with an RCE instance and typing `ENV.JWT` into the JavaScript console.  If you do these things you will pull real data from Canvas into the RCE demo environment.

### Adding New Plugins

If you are creating a plugin that works with Canvas RCE , you should also put in the appropriate
fake data which can be done in the [fake data store](./src/sidebar/sources/fake.js).

Custom plugins live under the plugins [directory](./src/rce/plugins/).

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
