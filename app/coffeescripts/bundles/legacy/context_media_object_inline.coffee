require [
  "jquery",
  "media_comments"
], ($) ->
  $(document).ready ->
    $("#media_comment").mediaComment "show_inline", ENV.MEDIA_OBJECT_ID, ENV.MEDIA_OBJECT_TYPE