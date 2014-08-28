require [
  "jquery",
  "jquery.instructure_misc_plugins"
], ($) ->
  $(document).ready ->
    $("#messages").delegate ".delete_link", "click", (event) ->
      event.preventDefault()
      $message = $(this).parents(".facebook_message")
      $message.confirmDelete
        noMessage: true
        url: $(this).attr("rel")
        success: ->
          $(this).slideUp ->
            $(this).remove()