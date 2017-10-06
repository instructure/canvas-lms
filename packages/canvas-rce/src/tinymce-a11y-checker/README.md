# TinyMCE Accessibility Checker Plugin

## Installation

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