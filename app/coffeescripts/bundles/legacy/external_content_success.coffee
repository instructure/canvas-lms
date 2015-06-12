require [
  "jquery",
  "i18n!external_content.success",
  "jquery.ajaxJSON",
  "jquery.instructure_misc_helpers"
], ($, I18n) ->

  dataReady = (data) ->
    if parentWindow[callback] and parentWindow[callback].ready
      event = jQuery.Event( "externalContentReady" )
      event.contentItems = data
      parentWindow.$(parentWindow).trigger "externalContentReady", event
      parentWindow[callback].ready data
      setTimeout (->
        if callback == 'external_tool_dialog'
          $("#dialog_message").text I18n.t("popup_success", "Success! This popup should close on its own...")
        else
          $("#dialog_message").text ''
      ), 1000
    else
      $("#dialog_message").text I18n.t("content_failure", "Content retrieval failed, please try again or notify your system administrator of the error.")
  data = ENV.retrieved_data
  callback = ENV.service
  parentWindow = window.parent
  parentWindow = parentWindow.parent while parentWindow and parentWindow.parent isnt parentWindow and not parentWindow[callback]
  if ENV.oembed
    url = $.replaceTags($.replaceTags($("#oembed_retrieve_url").attr("href"), "endpoint", encodeURIComponent(ENV.oembed.endpoint)), "url", encodeURIComponent(ENV.oembed.url))
    $.ajaxJSON url, "GET", {}, ((data) ->
      dataReady data
    ), ->
      $("#dialog_message").text I18n.t("oembed_failure", "Content retrieval failed, please try again or notify your system administrator of the error.")
  else
    dataReady data
