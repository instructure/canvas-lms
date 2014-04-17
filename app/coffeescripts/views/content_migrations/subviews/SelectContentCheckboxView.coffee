define [
  'jquery'
  'Backbone'
  'jst/content_migrations/subviews/SelectContentCheckbox'
  'i18n!select_content_checkbox'
], ($, Backbone, template, I18n) -> 
  class SelectContentCheckbox extends Backbone.View
    template: template

    events: 
      'click [name=selective_import]' : 'updateModel'

    updateModel: (event) -> 
      @model.set 'selective_import', $(event.currentTarget).val() == "true"

    # validations this form element. This validates method is a convention used 
    # for all sub views.
    # ie:
    #   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
    # -----------------------------------------------------------------------
    # @expects void
    # @returns void | object (error)
    # @api private

    validations: -> 
      errors = {}
      selective_import = @model.get('selective_import')

      if selective_import == null || selective_import == undefined
        errors.selective_import = [
          type: "required"
          message: I18n.t('select_content_error', "You must choose a content option")
        ]

      errors
