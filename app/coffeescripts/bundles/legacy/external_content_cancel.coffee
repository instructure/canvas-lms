require [
  "jquery",
  "i18n!external_content.cancel"
], ($, I18n) ->
  window.parentWindow = window.parent
  window.callback = ENV.service
  parentWindow = parentWindow.parent  while parentWindow and not parentWindow[callback]
  if parentWindow[callback] and parentWindow[callback].cancel
    parentWindow.$(parentWindow).trigger "externalContentCancel"
    parentWindow[callback].cancel()
    setTimeout (->
      $("#dialog_message").text I18n.t("popup_success", "Canceled. This popup should close on its own...")
    ), 1000
  else
    $("#dialog_message").text I18n.t("popup_failure", "Cannot find the parent window, you'll need to close this popup manually.")
