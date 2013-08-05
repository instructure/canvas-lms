define [
  'jquery'
  'Backbone'
  'jst/Modules/ModuleView'
  'compiled/views/Modules/ModuleItemCollectionView'
  'i18n!context_modules'
], ($, Backbone, template, ModuleItemCollectionView, I18n) ->

  class ModuleView extends Backbone.View

    template: template

    els:
      '.module_items': '$items'

    afterRender: ->
      @itemsView = new ModuleItemCollectionView
        collection: @model.itemCollection
        el: @$items
      @itemsView.render()

      super