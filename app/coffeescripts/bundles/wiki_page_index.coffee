require [
  'compiled/collections/WikiPageCollection'
  'compiled/views/wiki/WikiPageIndexView'
], (WikiPageCollection, WikiPageIndexView) ->

  view = new WikiPageIndexView
    collection: new WikiPageCollection

  view.collection.fetch({data: {sort:'title',per_page:30}}).then ->
    view.fetched = true
    # Re-render after fetching is complete, but only if there are no pages in the collection
    view.render() if view.collection.models.length == 0

  view.render()
