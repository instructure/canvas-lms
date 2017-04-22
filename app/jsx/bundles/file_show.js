import $ from 'jquery'
import 'jquery.doc_previews'
import 'jquery.instructure_misc_plugins'

const previewDefaults = {
  height: '100%',
  scribdParams: {
    auto_size: true
  }
}

const previewDiv = $('#doc_preview')
previewDiv.fillWindowWithMe()
previewDiv.loadDocPreview($.merge(previewDefaults, previewDiv.data()))
