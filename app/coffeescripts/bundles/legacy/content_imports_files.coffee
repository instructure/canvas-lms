require [
  "jquery"
  "i18n!content_imports.files"
], ($, I18n) ->
  $ ->
    $("#zip_file_import_form .cancel_button").attr("href", ENV.return_or_context_url).text (if ENV.return_to then I18n.t("buttons.cancel", "Cancel") else I18n.t("buttons.skip", "Skip this Step"))

