require [
  "jquery"
], ($) ->
  $(document).ready ->
    $(".data_view").change(->
      if $(this).val() is "paper"
        $("#submission_preview").removeClass("plain_text").addClass "paper"
      else
        $("#submission_preview").removeClass("paper").addClass "plain_text"
    ).change()