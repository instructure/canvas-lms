define [
  'jquery'
  'Backbone'
  'compiled/views/modules/ModuleCollectionView'
], ($, Backbone, ModuleCollectionView) ->
  module 'ModuleCollectionView'

  test "adds editable class to the div of the collection view", ->
    moduleCollectionView = new ModuleCollectionView(collection: new Backbone.Collection, editable: true)
    ok moduleCollectionView.render().$el.find('.collectionViewItems').is('.editable'), "has a css class of editable"
