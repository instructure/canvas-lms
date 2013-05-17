require [
  'jquery'
  'jquery.doc_previews'
  'jquery.instructure_misc_plugins'
], ($) ->

  previewDefaults =
    height: '100%'
    scribdParams:
        auto_size: true

  previewDiv = $("#doc_preview")
  previewDiv.fillWindowWithMe()
  previewDiv.loadDocPreview $.merge(previewDefaults, previewDiv.data())
