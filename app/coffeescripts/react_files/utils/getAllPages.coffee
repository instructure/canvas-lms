define [], ->
  # TODO: don't use this and use scroll position to only load the pages we need
  getAllPages = (modelOrCollection, onUpdate) ->
    return if modelOrCollection.loadedAll
    promise = modelOrCollection.fetch(page: 'next')
    promise.then(onUpdate)
    promise.pipe ->
      getAllPages(modelOrCollection, onUpdate)
