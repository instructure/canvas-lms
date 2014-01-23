require [
  "jquery",
  "i18n!facebook.settings"
], ($, I18n) ->
  $(document).ready ->
    $(".settings_link,.cancel_button").click (event) ->
      event.preventDefault()
      $("#notification_types_form,#notification_types_list").toggle()

    $("#notification_types_form").submit ->
      $(this).find("button").attr("disabled", true).text I18n.t("updating_preferences", "Updating Preferences...")