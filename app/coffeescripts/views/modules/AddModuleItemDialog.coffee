define [
  'i18n!modules'
  'jquery'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/modules/AddModuleItemDialogWrapper'
  'jst/modules/AddModuleItemDialog'
  'compiled/views/modules/ModuleItemViewRegister'
], (I18n, $, _, DialogFormView, wrapperTemplate, template, ModuleItemViewRegister) ->
  class AddModuleItemDialog extends DialogFormView
    wrapperTemplate: wrapperTemplate
    template: template
    className: 'dialogFormView form-horizontal'
    @optionProperty 'moduleName'
    @optionProperty 'moduleItemTypes'
    
    events: 
      "change [name='module_item[type]']" : "insertView"

    els:
      '#moduleItemOptionsContainer' : '$moduleItemOptionsContainer'
      "[name='module_item[type]']"  : '$select'

    initialize: (options) ->
      dialogDefaults =
        title: I18n.t "dialog_title", "Add item to %{moduleName}", moduleName: options.moduleName
        width: 600
        height: 400
      super _.extend {}, dialogDefaults, options

    afterRender: -> @swapView @$select.val()
    insertView: (event) -> @swapView $(event.target).val()

    # Swap view looks up the view that was selected by the register and 
    # swaps it in the moduleItemOptionsContainer. 
    
    swapView: (key) =>
      itemView = ModuleItemViewRegister.views[key]
      @$moduleItemOptionsContainer.html itemView.render().el if itemView
