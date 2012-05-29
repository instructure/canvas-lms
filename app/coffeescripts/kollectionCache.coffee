define [
  'compiled/models/Kollection'
  'compiled/models/KollectionItem'
  'compiled/collections/KollectionCollection'
], (Kollection, KollectionItem, KollectionCollection) ->

  kollectionCache =
    cache:
      kollectionCollections: {}
      kollections: {}
      kollectionItems: {}

    findOrCreateKollection: (kollectionId) ->
      @cache.kollections[kollectionId] ||= new Kollection(id: kollectionId)

    findOrCreateKollectionItem: (itemId, kollectionId) ->
      @cache.kollectionItems[itemId] ||= do =>
        if kollectionId
          kollection = @findOrCreateKollection kollectionId
          kollection.kollectionItems.get(itemId) ||
          kollection.kollectionItems.add(id: itemId).get(itemId)
        else
          new KollectionItem(id: itemId)

    findOrCreateKollectionCollection: (contextId, contextType) ->
      @cache.kollectionCollections["#{contextType}_#{contextId}"] ||=
        new KollectionCollection(url: "api/v1/{contextType}/#{contextId}/collections")

