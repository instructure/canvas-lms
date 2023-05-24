# Canvas Rich Content Editor - Development Guide

This guide is written for those planning to develop `canvas-rce` itself. It will
guide you to getting things set up in a way that allows you to get off the
ground and get going quickly.

## Canvas RCE API

In order for all features of `canvas-rce` to work you'll also need a running copy
of `canvas-rce-api`. You can get it from [canvas-rce-api](https://github.com/instructure/canvas-rce-api). You'll want to follow the setup instructions for it in that repository as
they will be the most up to date.

To configure canvas to find the canvas-rce-api, include in `canvas-lms/config/dynamic_settings.yml`:

```yaml
development:
  config:
    canvas:
      rich-content-service:
        app-host: "localhost:3001"
```

And in `canvas-lms/config/vault_contents.yml`:

```yaml
      canvas_security:
        encryption_secret: "astringthatisactually32byteslong"
        signing_secret: "astringthatisactually32byteslong"
```

## Developing

You can get the "demo" development environment up and running by executing:

```shell
yarn demo:dev
```

Then navigate to http://localhost:8080/ and you will see the `canvas-rce` editor.
Any changes you make to files under `/src` will be reflected in this editor.

### Standalone demo

```shell
yarn demo:build
yarn demo
```

Builds then loads the demo from the filesystem.

### Developing inside Canvas

Because this package lives in the Canvas packages workspace, you can make modifications to it without first needing to do a `yarn install` in Canvas.

You can start up the watch mode of this package by running `yarn build:watch` inside the `canvas-rce` directory. Then in Canvas proper, you can run `yarn build:js:watch` and things generally work out. If for some reason you get errors with the watch modes, you can fallback to the regular builds `yarn build:canvas` inside of `canvas-rce` and `yarn build:js` inside of Canvas.

## Plugins

Some Canvas specific plugins require using the [Canvas RCE API](#Canvas-RCE-API) (RCE), but the
`CanvasRce` React component will remove those features if the props necessary for
connecting to the RCS are not provided.

_This is not currently working_:

There is a section available on the page that allows you to connect to a real `canvas-rce-api`instance and to a real Canvas instance. You can put a URL pointing to a running
`canvas-rce-api` instance as well as a JWT from Canvas. You can get the JWT from Canvas by
going to any page with an RCE instance and typing `ENV.JWT` into the JavaScript console. If you do these things you will pull real data from Canvas into the RCE demo environment.

### Adding New Plugins

If you are creating a plugin that works with Canvas RCE , you should also put in the appropriate
fake data which can be done in the [fake data store](./src/rcs/fake.js).

Custom plugins live under the plugins [directory](./src/rce/plugins/).

## Adding new Modals and Trays

or anything else that gets mounted in a react portal comes with 2 requirements

1. Include the attribute `data-mce-component={true}` on the `<Modal>` or ` <Tray>`. This tells the RCE
   that the modal is part of the RCE and not to fire a `blur` event when it closes and loses focus.
1. Include `mountNode={instuPopupMountNode}` on thew `<Modal>` or `<Tray>`. The `instuiPopupMountNode`
   function is imported from `src/util/fullscreenHelpers` within the `canvas-rce` package or `@instructure/canvs-rce` from outside. This function will mount modals in the `<div class="rce-wrapper">` when the RCE is fullscreen, where it will not be hidden behind the RCE.

## Upgrading TinyMCE

Update the version of `tinymce` and `@tinymce/tinymce-react` in `packge.json`, run `yarn install` and hope for the best.

Note: I would think that since `tinymce` is a dependency of `@tinymce/tinymce-react` it would not have to be listed as a dependency of the rce.
When removed we have build problems, so the simplest solution is to leave it in.
Make sure the specified semver is compatible with `tinymce-react`'s dependency
specification.

## Adding/Updating Languages

### TinyMCE Language Pack

Translations for TinyMCE are not shipped with the `tinymce` npm package. When
upgrading to a new version be sure to download the latest language packs. Visit
<https://www.tiny.cloud/get-tiny/language-packages/> and select all languages. It
is easier to just download all and only commit the changes to existing files
than try to only select the locales currently used. Download the file and
extract all of th `.js` files to `./src/translations/tinymce/`.

After commiting the
changed locale files you can run `git clean -f ./src/rce/languages/` to remove
the untracked language files.

### Locale Code Mappings

Since different projects have a hard time agreeing on locale code format, a file
mapping Canvas locale codes to TinyMCE locale codes needs to be updated. This is
found in `./src/rce/editorLanguage.js`. Check this is still correct.

### Locale Module

A locale module for each canvas translations + tinymce translations
exists for each locale. These files are generated by `yarn installTranslations`
and live in `./src/translations/locales`. Periodically checking if the list canvas provided translation files in`packages/translations/lib/canvas-rce`have changed and then the mapping to tinymce in`editorLanguage.js` would also be useful.

After updating, check that the mapping between canvas locales and the tinymce
locale-based filenames in `src/rce/editorLanguage.js` are still correct. Then
run `yarn installTranaslations` (which is also run as part of the build).

### Recognized Languages

The `./src/rce/normalizeLocale.js` file includes a list of valid locales. Any
new locales should be added here.

### Extending the UI

You can add your own items to the RCE's toolbar and menubar. The added items will only appear
in the UI if the plugin that registered the buttons and menu_items with tinymce has been loaded.
A simply way of controlling the UI is to add the toolbar and menu items, then selectively
add the corresponding plugins.

#### Adding plugins:

The <CanvasRce> plugins prop is simply an array of plugin names. These names have been
registered with tinymce via

```
tinymce.PluginManager.add(plugin_name, plugin_definition)
```

The provided list of plugins is merged with the default list and given to tinymce. It is
your responsibility to import the file containing the plugin.

#### Adding to the toolbar:

The <CanvasRce> toolbar prop looks like

```
[{
  name: 'format',
  items: ['this', 'that', 'another']
}]
```

The RCE will add the `this`, `that`, and `another` toolbar items to the `format` toolbar.
The items are the names registered with tinymce with `editor.ui.registry.addButton` by some plugin.
See any of the `plugin.ts` files under `src/rce/plugins` for examples. If the named toolbar exists,
the items are merged in, removing any duplicates and appending the rest. If the
named toolbar does not exist, it is created.

#### Adding to the menubar:

The <CanvasRce> menu props looks like

```
{
  tools: {
    title: "My Tools",
    items: "this that another"
  }
}
```

This RCE will add the `items` to the `tools` menu. The items are menu_items registered
with tinymce with `ed.ui.registry.addMenuItem`. Like the toolbar, if the
menu exists duplicates are removed and the remaining the items are appended to the menu.
If the menu does not exist, it is created and `title` is its label.

## Miscelaneous Advice

- When possible, delegate to tinymce to the work of manipulating the content. In the end
  you'll be happier.
- CanvasRce prop types are documented in the source file
- If autosave is turned on, you should call RCEWrapper.RCEClosed() to remove it
  if your user exits the page normally (e.g. via Cancel or Save)
