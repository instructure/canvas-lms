require [
  "i18n!shared.error_form",
  "jquery",
  "str/htmlEscape",
  "jquery.instructure_forms",
  "jquery.loadingImg",
  "compiled/jquery.rails_flash_notifications"
], (I18n, $, htmlEscape) ->
  $(document).ready ->
    $(".submit_error_link").click (event) ->
      event.preventDefault()
      $("#submit_error_form").slideToggle ->
        $("#submit_error_form :input:visible:first").focus().select()

    $("#submit_error_form").formSubmit
      formErrors: false
      beforeSubmit: (data) ->
        $(this).loadingImage()

      success: (data) ->
        $(this).loadingImage "remove"
        $.flashMessage(I18n.t("message_sent", "Thank you for your help!  We'll get right on this."))
        $("#submit_error_form").slideToggle()

      error: (data) ->
        $(this).loadingImage "remove"
        $(this).errorBox I18n.t("message_failed", "Report didn't send.  Please try again.")