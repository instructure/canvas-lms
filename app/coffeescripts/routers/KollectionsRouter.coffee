define [
  'Backbone'
  'underscore'
  'compiled/kollectionCache'
  'compiled/views/Kollections/ShowView'
  'compiled/views/KollectionItems/ShowView'
], (Backbone, _, kollectionCache, ShowView, KollectionItemShowView) ->

  class KollectionsRouter extends Backbone.Router

    routes:
      'collections/:collection_id' : 'collectionShow'
      'collections/:collection_id/collection_items/:item_id' : 'collectionItemShow'

    collectionShow: (id) ->
      id = Number(id)
      model = kollectionCache.findOrCreateKollection(id)
      view = new ShowView
        model: model
      view.render()

    collectionItemShow: (kollectionId, itemId) ->
      kollectionId = Number kollectionId
      itemId = Number itemId
      model = kollectionCache.findOrCreateKollectionItem(itemId, kollectionId)

      view = new KollectionItemShowView
        model: model
        el: '#collectionsApp'
        fullView: true
      view.render()
      model.fetch()
