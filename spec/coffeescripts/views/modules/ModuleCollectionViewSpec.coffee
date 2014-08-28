define [
  'jquery'
  'Backbone'
  'compiled/views/modules/ModuleCollectionView'
  'helpers/fakeENV'
], ($, Backbone, ModuleCollectionView, fakeENV) ->
  module 'ModuleCollectionView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test "adds editable class to the div of the collection view", ->
    moduleCollectionView = new ModuleCollectionView(collection: new Backbone.Collection, editable: true)
    ok moduleCollectionView.render().$el.find('.editable').length == 1, "has a css class of editable"
