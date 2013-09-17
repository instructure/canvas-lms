define [
  'Backbone'
  'jst/content_migrations/subviews/ChooseMigrationFile'
  'i18n!content_migrations'
], (Backbone, template, I18n) ->
  class ChooseMigrationFile extends Backbone.View
    template: template

    els: 
      '#migrationFileUpload' : '$migrationFileUpload'

    events: 
      'change #migrationFileUpload' : 'setAttributes'

    @optionProperty 'fileSizeLimit'

    setAttributes: (event) -> 
      filename = event.target.value.replace(/^.*\\/, '')
      fileElement = @$migrationFileUpload[0]

      @model.set('pre_attachment', {file_size: @fileSize(fileElement), name: filename, fileElement: fileElement})
    
    # TODO 
    #   Handle cases for file size from IE browsers
    # @api private

    fileSize: (fileElement) -> fileElement.files?[0].size

    # Validates this form element. This validates method is a convention used 
    # for all sub views.
    # ie:
    #   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
    # -----------------------------------------------------------------------
    # @expects void
    # @returns void | object (error)
    # @api private

    validations: -> 
      errors = {}
      preAttachment = @model.get('pre_attachment')
      fileErrors = []
      fileElement = preAttachment?.fileElement

      unless preAttachment?.name && fileElement
        fileErrors.push
                    type: "required"
                    message: I18n.t("file_required", "You must select a file to import content from")

      if @fileSize(fileElement) > @fileSizeLimit
        fileErrors.push
                    type: "upload_limit_exceeded"
                    message: I18n.t("file_too_large", "Your migration cannot exceed %{file_size}", file_size: @humanReadableSize(@fileSizeLimit))

      errors.file = fileErrors if fileErrors.length
      errors

    # Converts a size to a human readible string. "size" should be in
    # bytes to stay consistent with the javascript files api. 
    # --------------------------------------------------------------
    # @expects size (bytes | string(in bytes))
    # @returns readableString (string)
    # @api private

    humanReadableSize: (size) -> 
      size = parseFloat size #Ensure we are working with a number
      units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
      i = 0
      while(size >= 1024) 
          size /= 1024
          ++i

      size.toFixed(1) + ' ' + units[i]
