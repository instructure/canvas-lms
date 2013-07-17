define [
  'jquery'
  'Backbone'
  'jst/modules/ModuleView'
  'compiled/views/modules/ModuleItemCollectionView'
  'i18n!context_modules'
], ($, Backbone, template, ModuleItemCollectionView, I18n) ->

  class ModuleView extends Backbone.View

    template: template
    className: 'module item-group-condensed'

    els:
      '.module_items': '$items'

    afterRender: ->
      @itemsView = new ModuleItemCollectionView
        collection: @model.itemCollection
        el: @$items
      @itemsView.render()

      super
