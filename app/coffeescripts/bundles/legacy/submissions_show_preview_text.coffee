require [
  "jquery"
], ($) ->
  $(document).ready ->
    # this is so iOS devices can scroll submissions in speedgrader
    $("body,html").css({
      "height": "100%",
      "overflow": "auto",
      "-webkit-overflow-scrolling": "touch"
    })

    $(".data_view").change(->
      if $(this).val() is "paper"
        $("#submission_preview").removeClass("plain_text").addClass "paper"
      else
        $("#submission_preview").removeClass("paper").addClass "plain_text"
    ).change()