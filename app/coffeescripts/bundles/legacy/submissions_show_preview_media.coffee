require [
  "jquery",
  "media_comments"
], ($, _mediaComments) ->
  $(document).ready ->
    $(".play_media_recording_link").click (event) ->
      event.preventDefault()
      id = $(".media_comment_id:first").text()
      $("#media_recording_box .box_content").mediaComment "show_inline", id
      $(this).remove()

    $(".play_media_recording_link").mediaCommentThumbnail()

