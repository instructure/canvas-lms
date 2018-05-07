# TinyMCE Accessibility Checker Plugin _(tinymce-a11y-checker)_

> An accessibility checker plugin for TinyMCE.

## Install

You will need to have an instance of TinyMCE setup prior to using this plugin.

```bash
npm install tinymce-a11y-checker --save

# or

yarn add tinymce-a11y-checker
```

## Usage

```js
import tinymce from "tinymce"
import "tinymce-a11y-checker"

tinymce.init({
  selector: "#editor",
  plugins: ["a11y_checker"],
  toolbar: "check_a11y | bold italic ..."
})
```

## Contribute

See [the contributing file](CONTRIBUTING.md)!

PRs accepted.

[MIT](../LICENSE)
