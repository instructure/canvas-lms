define [
  'Backbone',
  'jquery',
  'jst/quizzes/fileUploadQuestionState',
  'jst/quizzes/fileUploadedOrRemoved',
  'underscore',
  'jquery.instructure_forms',
  'jquery.disableWhileLoading'
], ({View}, $, template,uploadedOrRemovedTemplate,_) ->

  class FileUploadQuestion extends View

    # TODO: Handle quota errors?
    # TODO: Handle upload errors?

    els:
      '.file-upload': '$fileUpload'
      '.file-upload-btn': '$fileDialogButton'
      '.attachment-id': '$attachmentID'
      '.file-upload-box': '$fileUploadBox'

    events:
      'change input.file-upload': 'checkForFileChange'
      'click .file-upload-btn': 'openFileBrowser'
      'click .delete-attachment': 'deleteAttachment'

    checkForFileChange: (event) =>
      # Stop the bubbling of the event so the question doesn't
      # get marked as read before the file is uploaded.
      event.preventDefault()
      event.stopPropagation()
      if @$fileUpload.val()
        @deferred = new $.Deferred()
        @removeFileStatusMessage()
        @$fileUploadBox.disableWhileLoading(@deferred)
        @uploadAttachment()

    uploadAttachment: =>
      $.ajaxJSONPreparedFiles
        files: @$fileUpload
        handle_files: @processAttachments
        uploadDataUrl: ENV.UPLOAD_URL

    openFileBrowser: =>
      @$fileUpload.click()

    render: =>
      super
      @$fileUploadBox.html template @model || {}
      this

    removeFileStatusMessage: =>
      @$fileUploadBox.siblings('.file-status').remove()

    # For now we'll just process the first one.
    processAttachments: (attachments) =>
      @deferred.resolve()
      [@model,__] = attachments
      @$attachmentID.val(@model.id).trigger 'change'
      @$fileUploadBox.addClass 'file-upload-box-with-file'
      @render()
      @$fileUploadBox.parent().append uploadedOrRemovedTemplate(
        _.extend({},@model,{fileUploaded: true})
      )

    # For now we'll just remove it from the form, but not actually delete it
    # using the API in case teacher's need to see any uploaded files a
    # student may upload.
    deleteAttachment: (event) =>
      event.preventDefault()
      @$attachmentID.val("").trigger 'change'
      @$fileUploadBox.removeClass 'file-upload-box-with-file'
      oldModel = @model
      @model = {}
      @removeFileStatusMessage()
      @render()
      @$fileUploadBox.parent().append uploadedOrRemovedTemplate(
        _.extend({},oldModel,{fileUploaded: false})
      )

