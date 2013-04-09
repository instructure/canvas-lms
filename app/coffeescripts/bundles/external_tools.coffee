require [
  'compiled/collections/ExternalToolCollection',
  'compiled/views/ExternalTools/IndexView'
  ], (ExternalToolCollection, ExternalToolsIndexView) ->
    collection = new ExternalToolCollection()
    collection.fetch()
    view = new ExternalToolsIndexView
      el: '#external_tools'
      collection: collection
    view.render()