define [
  'jquery'
  'Backbone'
  'jst/modules/ModuleView'
  'compiled/views/modules/ModuleItemCollectionView'
  'i18n!context_modules'
  'compiled/views/modules/AddModuleItemDialog'
  'compiled/ModuleItemTypes'
  'compiled/views/modules/ModuleItemViewRegister'
], ($, Backbone, template, ModuleItemCollectionView, I18n, AddModuleItemDialog, MODULE_ITEM_TYPES, ModuleItemViewRegister) ->

  class ModuleView extends Backbone.View

    template: template
    className: 'module item-group-condensed'

    els:
      '.module_items': '$items'

    events: 
      'click .add-item-button' : 'displayNewItemDialog'

    displayNewItemDialog: (event) ->
      event.preventDefault()
      addModuleItemDialog = new AddModuleItemDialog 
                              moduleName: 'This modules name'
                              moduleItemTypes: MODULE_ITEM_TYPES
      addModuleItemDialog.open()

    afterRender: ->
      @itemsView = new ModuleItemCollectionView
        collection: @model.itemCollection
        el: @$items
      @itemsView.render()

      super
