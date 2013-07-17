require [
  'jquery'
  'media_comments'
], ($) ->

  $preview = $("#media_preview")
  data = $preview.data()
  $preview.mediaComment('show_inline', 'maybe', data.type, data.download_url)
