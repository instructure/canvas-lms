define [
  'jquery'
], ($) ->

  ###
  # builds and interacts with hidden input file for kaltura uploads
  ###
  class FileInputManager

    constructur: ->
      @allowedMedia = ['audio', 'video']

    resetFileInput: (callback, id, parentId) =>
      id ||= 'file_upload'
      parentId ||= '#media_upload_settings'
      if @$fileInput
        @$fileInput.off 'change', callback
        @$fileInput.remove()
      fileInput = "<input id='#{id}' type='file' style='display: none;'>"
      $(parentId).append(fileInput)
      @$fileInput = $("##{id}")
      @$fileInput.on 'change', callback

    setUpInputTrigger: (el, mediaType) ->
      $(el).on 'click', (e) =>
        @allowedMedia = mediaType
        @$fileInput.click()

    getSelectedFile: ->
      @$fileInput.get()[0].files[0]

