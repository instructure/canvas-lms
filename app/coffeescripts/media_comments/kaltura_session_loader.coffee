define [
  'jquery'
], ( $
) ->
  ###
  # Loads kaltura session data, generates options based on session
  ###
  class KalturaSessionLoader

    loadSession: (url, success, failure) =>
      successCB = success
      failureCB = failure
      $.ajaxJSON url, 'POST', {}, (data) =>
        if (data.ks)
          data.ui_conf_id = INST.kalturaSettings.upload_ui_conf
          @kalturaSession = data
          success.call()
        else
          failure.call()
      return true

    generateUploadOptions: (allowedMedia)->
      {
        kaltura_session: @kalturaSession
        allowedMediaTypes: allowedMedia
        uploadUrl: @kalturaUrl '/index.php/partnerservices2/upload'
        entryUrl: @kalturaUrl '/index.php/partnerservices2/addEntry'
        uiconfUrl: @kalturaUrl '/index.php/partnerservices2/getuiconf'
        entryDefaults:
          partnerData: $.mediaComment.partnerData()
      }

    kalturaUrl: (endPoint) ->
      location.protocol + '//' + INST.kalturaSettings.domain + endPoint

