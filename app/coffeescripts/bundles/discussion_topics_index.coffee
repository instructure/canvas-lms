require [
  'i18n!discussions'
  'Backbone'
  'compiled/collections/DiscussionTopicsCollection'
  'compiled/views/DiscussionTopics/DiscussionListView'
  'compiled/views/DiscussionTopics/IndexView'
], (I18n, {Router}, DiscussionTopicsCollection, DiscussionListView, IndexView) ->

  class DiscussionIndexRouter extends Router

    routes:
      '': 'index'

    initialize: ->
      @openDiscussions = new DiscussionListView
        collection: new DiscussionTopicsCollection
        className: 'open'
        title: I18n.t('open_discussions', 'Open Discussions')
        listID: 'open-discussions'

      @lockedDiscussions = new DiscussionListView
        collection: new DiscussionTopicsCollection
        className: 'locked'
        title: I18n.t('locked_discussions', 'Locked Discussions')
        listID: 'locked-discussions'

    index: ->
      @view = new IndexView
        openDiscussionView:   @openDiscussions
        lockedDiscussionView: @lockedDiscussions
        permissions:          ENV.permissions
        atom_feed_url:        ENV.atom_feed_url

      @view.render()
      @fetchDiscussions()
      @attachCollections()

    fetchDiscussions: ->
      @discussions = new DiscussionTopicsCollection
      @discussions.fetch(add: true, data: { order_by: 'recent_activity', per_page: 50 })
      @finished = false

    attachCollections: ->
      @openDiscussions.collection.on('change:locked',   @swapModel)
      @lockedDiscussions.collection.on('change:locked', @swapModel)
      @discussions.on('fetch', @onFetch)
      @discussions.on('fetched:last', @onFetchedLast)

    onFetch: (collection, models) =>
      setTimeout((=> @discussions.fetch(add: true, page: 'next') unless @finished), 0)
      @partitionCollection(collection)

    onFetchedLast: =>
      @finished = true
      @openDiscussions.collection.trigger('fetched:last')
      @lockedDiscussions.collection.trigger('fetched:last')

    partitionCollection: (collection) ->
      group = collection.groupBy((model) -> if model.get('locked') then 1 else 0)
      group[0] or= []
      group[1] or= []
      @openDiscussions.collection.add(group[0])
      @lockedDiscussions.collection.add(group[1])

    swapModel: (m) =>
      newCollection  = if m.get('locked') then @lockedDiscussions else @openDiscussions
      oldCollection  = if m.get('locked') then @openDiscussions   else @lockedDiscussions
      oldCollection.collection.remove(m)
      newCollection.collection.add(m)

  router = new DiscussionIndexRouter
  Backbone.history.start()
