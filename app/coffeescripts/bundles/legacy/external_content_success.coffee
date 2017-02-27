require [
  "jquery",
  "i18n!external_content.success",
  "jquery.ajaxJSON",
  "jquery.instructure_misc_helpers",
  'compiled/jquery.rails_flash_notifications'
], ($, I18n) ->

  dataReady = (data, service_id) ->

    e = $.Event( "externalContentReady" )
    e.contentItems = data
    e.service_id = service_id
    parentWindow.$(parentWindow).trigger "externalContentReady", e

    if parentWindow[callback] and parentWindow[callback].ready
      parentWindow[callback].ready data
      setTimeout (->
        if callback == 'external_tool_dialog'
          $("#dialog_message").text I18n.t("popup_success", "Success! This popup should close on its own...")
        else
          $("#dialog_message").text ''
      ), 1000
    else
      $("#dialog_message").text I18n.t("content_failure", "Content retrieval failed, please try again or notify your system administrator of the error.")

  lti_response_messages = ENV.lti_response_messages
  service_id = ENV.service_id
  data = ENV.retrieved_data
  callback = ENV.service
  parentWindow = window.parent
  parentWindow = parentWindow.parent while parentWindow and parentWindow.parent isnt parentWindow and not parentWindow[callback]

  parentWindow.$.flashError(lti_response_messages['lti_errormsg']) if lti_response_messages['lti_errormsg']
  parentWindow.$.flashMessage(lti_response_messages['lti_msg']) if lti_response_messages['lti_msg']

  if ENV.oembed
    url = $.replaceTags($.replaceTags($("#oembed_retrieve_url").attr("href"), "endpoint", encodeURIComponent(ENV.oembed.endpoint)), "url", encodeURIComponent(ENV.oembed.url))
    $.ajaxJSON url, "GET", {}, ((data) ->
      dataReady data
    ), ->
      $("#dialog_message").text I18n.t("oembed_failure", "Content retrieval failed, please try again or notify your system administrator of the error.")
  else
    dataReady data, service_id
