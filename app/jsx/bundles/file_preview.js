require [
  'jquery'
  'media_comments'
], ($) ->

  $preview = $("#media_preview")
  data = $preview.data()
  $preview.mediaComment('show_inline', data.media_entry_id || 'maybe', data.type, data.download_url)
  if ENV.NEW_FILES_PREVIEW
    $('#media_preview').css({"margin":"0", "padding": "0", "position": "absolute", "top": "50%", "left": "50%", "-webkit-transform": "translate(-50%, -50%)", "transform": "translate(-50%, -50%)"})
