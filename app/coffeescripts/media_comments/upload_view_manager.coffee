define [
  'jquery',
  'i18n!media_comments',
  'jqueryui/progressbar',
  'jquery.instructure_misc_helpers'
], ($,
    I18n
) ->

  ###
  # Watches uploader and updates UI with file upload details, errors
  # and upload progress
  ###
  class UploadViewManager

    monitorUpload: (uploader, allowedMedia, file) ->
      @resetListeners() if @uploader && @uploader != uploader
      @uploader = uploader
      @allowedMedia = allowedMedia
      @showProgBar()
      @showFileDetails(file)
      @uploader.addEventListener 'K5.uiconfError', @showConfigError
      @uploader.addEventListener 'K5.error', @showConfigError
      @uploader.addEventListener 'K5.fileError', @onFileTypeError
      @uploader.addEventListener 'K5.progress', @updateProgBar

    resetListeners: ->
      @uploader.removeEventListener 'K5.uiconfError', @showConfigError
      @uploader.removeEventListener 'K5.error', @showConfigError
      @uploader.removeEventListener 'K5.fileError', @onFileTypeError
      @uploader.removeEventListener 'K5.progress', @updateProgBar

    onFileTypeError: (error) =>
      if (error.maxFileSize > error.file.size)
        message = I18n.t('file_size_error', 'Size of %{file} is greater than the maximum %{max} allowed file size.',{file: error.file.name, max: error.maxFileSize})
      else
        message = I18n.t('file_type_error', '%{file} is not an acceptable %{type} file.', {file: error.file.name, type: error.allowedMediaTypes[0]})
      @resetFileDetails()
      @showErrorMessage(message)

    showConfigError: =>
      message = I18n.t('errors.media_comment_installation_broken', "Media comment uploading has not been set up properly. Please contact your administrator.")
      @showErrorMessage(message)
      $("#media_upload_feedback").css('visibility', 'visible')
      $('#audio_upload_holder').css('visibility', 'hidden')
      $('#video_upload_holder').css('visibility', 'hidden')
      $('#media_upload_settings').css('visibility', 'hidden')

    resetFileDetails: ->
      $('#media_upload_settings').css('visibility', 'hidden')
      $('#media_upload_title').val('')
      $('#media_upload_display_title').text('')
      $('#media_upload_file_size').text($.fileSize(0))
      $("#media_upload_settings .icon").attr('src', "/images/file.png")

    showFileDetails: (file) ->
      if !file
        @resetFileDetails()
        return
      $('#media_upload_feedback').css('visibility', 'hidden')
      $('#media_upload_settings').css('visibility', 'visible')
      $('#media_upload_title').val(file.name)
      $('#media_upload_display_title').text(file.name)
      $('#media_upload_file_size').text($.fileSize(file.size))
      $("#media_upload_settings .icon").attr('src', "/images/file-#{@allowedMedia[0]}.png")
      $("#media_upload_submit").attr('disabled', true).text(I18n.t('messages.submitting', "Submitting Media File..."))

    showErrorMessage: (message) ->
      @hideProgBar()
      $('#media_upload_feedback').css('visibility', 'visible')
      $("#media_upload_feedback_text").html(message)

    showProgBar: ->
      $('#media_upload_progress').css('visibility', 'visible').progressbar()

    hideProgBar: ->
      $('#media_upload_progress').css('visibility', 'hidden')

    updateProgBar: (data) ->
      prc = ((data.loaded / data.total) * 100.0)
      $('#media_upload_progress').progressbar('option', 'value', prc)
