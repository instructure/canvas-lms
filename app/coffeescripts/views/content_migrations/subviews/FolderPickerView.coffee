define [
  'Backbone'
  'jst/content_migrations/subviews/FolderPicker'
], (Backbone, template) -> 
  class FolderPickerView extends Backbone.View
    template: template
    @optionProperty 'folderOptions'
    
    els: 
      ".migrationUploadTo" : "$migrationUploadTo"

    events: 
      "change .migrationUploadTo" : "setAttributes"

    setAttributes: (event) -> 
      @model.set('settings', folder_id: @$migrationUploadTo.val() if @$migrationUploadTo.val())

    toJSON: (json) -> 
      json = super
      json.folderOptions = @folderOptions || ENV.FOLDER_OPTIONS
      json

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
      settings = @model.get('settings')

      unless settings?.folder_id
        errors.migrationUploadTo = [
          type: "required"
          message: "You must select a folder to upload your migration to"
        ]

      errors

