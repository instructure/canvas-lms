define [
  'i18n!modules'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/modules/AddModuleItemDialogWrapper'
  'jst/modules/AddModuleItemDialog'
], (I18n, _, DialogFormView, wrapperTemplate, template) ->
  class AddModuleItemDialog extends DialogFormView
    wrapperTemplate: wrapperTemplate
    template: template
    className: 'dialogFormView form-horizontal'
    @optionProperty 'moduleName'
    @optionProperty 'moduleItemTypes'

    initialize: (options) ->
      dialogDefaults =
        title: I18n.t "dialog_title", "Add item to %{moduleName}", moduleName: options.moduleName
        width: 600
        height: 400
      super _.extend {}, dialogDefaults, options
