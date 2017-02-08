define [
  'Backbone',
  'jquery',
  'jst/quizzes/fileUploadQuestionState',
  'jst/quizzes/fileUploadedOrRemoved',
  'underscore',
  'jquery.instructure_forms',
  'jquery.disableWhileLoading'
], ({View}, $, template, uploadedOrRemovedTemplate, _) ->

  class FileUploadQuestion extends View

    # TODO: Handle quota errors?
    # TODO: Handle upload errors?

    els:
      '.file-upload': '$fileUpload'
      '.file-upload-btn': '$fileDialogButton'
      '.attachment-id': '$attachmentID'
      '.file-upload-box': '$fileUploadBox'

    events:
      'change input[type=file]': 'checkForFileChange'
      'click .file-upload-btn': 'openFileBrowser'
      'click .delete-attachment': 'deleteAttachment'

    checkForFileChange: (event) =>
      # Stop the bubbling of the event so the question doesn't
      # get marked as read before the file is uploaded.
      event.preventDefault()
      event.stopPropagation()
      if val = @$fileUpload.val()
        @removeFileStatusMessage()
        @model.set 'file', @$fileUpload[0]
        dfrd = @model.save(null, success: @processAttachment)
        @$fileUploadBox.disableWhileLoading dfrd

    openFileBrowser: (event) =>
      event.preventDefault()
      @$fileUpload.click()

    render: =>
      super
      # This unfortunate bit of browser detection is here because IE9
      # will throw an error if you programatically call "click" on the
      # input file element, get the file element, and submit a form.
      # For now, remove the input rendered in ERB-land, and the template is
      # responsible for rendering a fallback to a regular input type=file
      isIE = !!$.browser.msie
      @$fileUploadBox.html template _.extend({}, @model.present(), {isIE})
      @$fileUpload = @$ '.file-upload'
      this

    removeFileStatusMessage: =>
      @$fileUploadBox.siblings('.file-status').remove()

    # For now we'll just process the first one.
    processAttachment: (attachment) =>
      @$attachmentID.val(@model.id).trigger 'change'
      @$fileUploadBox.addClass 'file-upload-box-with-file'
      @render()
      @$fileUploadBox.parent().append uploadedOrRemovedTemplate(
        _.extend({}, @model.present(), {fileUploaded: true})
      )
      @trigger('attachmentManipulationComplete')

    # For now we'll just remove it from the form, but not actually delete it
    # using the API in case teacher's need to see any uploaded files a
    # student may upload.
    deleteAttachment: (event) =>
      event.preventDefault()
      @$attachmentID.val("").trigger 'change'
      @$fileUploadBox.removeClass 'file-upload-box-with-file'
      oldModel = @model.present()
      @model.clear()
      @removeFileStatusMessage()
      @render()
      @$fileUploadBox.parent().append uploadedOrRemovedTemplate(oldModel)
      @trigger('attachmentManipulationComplete')

