require [
  'i18n!discussions'
  'underscore'
  'Backbone'
  'compiled/collections/DiscussionTopicsCollection'
  'compiled/views/DiscussionTopics/DiscussionListView'
  'compiled/views/DiscussionTopics/IndexView'
], (I18n, _, {Router}, DiscussionTopicsCollection, DiscussionListView, IndexView) ->

  class DiscussionIndexRouter extends Router

    # Public: I18n strings.
    messages:
      lists:
        open:   I18n.t('open_discussions',   'Open Discussions')
        locked: I18n.t('locked_discussions', 'Locked Discussions')
        pinned: I18n.t('pinned_discussions', 'Pinned Discussions')

    # Public: Routes to respond to.
    routes:
      '': 'index'

    initialize: ->
      @discussions =
        open: @_createListView 'open',
          comparator: 'dateComparator'
          draggable: true
          destination: '.pinned.discussion-list'
          pinnable: ENV.permissions.change_settings
        locked: @_createListView 'locked',
          comparator: 'dateComparator'
          pinnable: false
        pinned: @_createListView 'pinned',
          comparator: 'positionComparator'
          destination: '.open.discussion-list'
          lockable: false
          sortable: true
          pinnable: ENV.permissions.change_settings

    # Public: The index page action.
    index: ->
      @view = new IndexView
        openDiscussionView:   @discussions.open
        lockedDiscussionView: @discussions.locked
        pinnedDiscussionView: @discussions.pinned
        permissions:          ENV.permissions
        atom_feed_url:        ENV.atom_feed_url
      @_attachCollections()
      @fetchDiscussions()
      @view.render()

    # Public: Fetch this context's discussions from the server. Use a new
    # DiscussionTopicsCollection and then sort/filter results on the client.
    #
    # Returns nothing.
    fetchDiscussions: ->
      pipeline = new DiscussionTopicsCollection
      pipeline.fetch(add: true, data: {order_by: 'recent_activity', per_page: 50})
      pipeline.on('fetch', @_onPipelineLoad)
      pipeline.on('fetched:last', @_onPipelineEnd)

    # Internal: Create a new DiscussionListView of the given type.
    #
    # type: The type of discussions this list will hold  Options are 'open',
    #   'locked', and 'pinned'.
    #
    # Returns a DiscussionListView object.
    _createListView: (type, options = {}) ->
      comparator = DiscussionTopicsCollection[options.comparator]
      delete options.comparator

      new DiscussionListView
        collection: new DiscussionTopicsCollection([], comparator: comparator)
        className: type
        title: @messages.lists[type]
        listID: "#{type}-discussions"
        itemViewOptions: options
        sortable: !!options.sortable
        draggable: !!options.draggable
        destination: options.destination

    # Internal: Attach events to the discussion topic collections.
    #
    # Returns nothing.
    _attachCollections: ->
      for key, view of @discussions
        view.collection.on('change:locked change:pinned', @moveModel)

    # Internal: Handle a page of discussion topic results, fetching the next
    # page if it exists.
    #
    # collection - The collection firing the fetch event.
    # models - The models fetched from the server.
    #
    # Returns nothing.
    _onPipelineLoad: (collection, models) =>
      @_sortCollection(collection)
      setTimeout((-> collection.fetch(add: true, page: 'next')), 0) if collection.urls.next

    # Internal: Handle the last page of discussion topic results, propagating
    # the event down to all of the filtered collections.
    #
    # Returns nothing.
    _onPipelineEnd: =>
      view.collection.trigger('fetched:last') for key, view of @discussions

    # Internal: Sort the given collection into the open, locked, and pinned
    # collections of topics.
    #
    # pipeline - The collection to filter.
    #
    # Returns nothing.
    _sortCollection: (pipeline) ->
      group = @_groupModels(pipeline)
      @discussions[key].collection.add(group[key]) for key of group

    # Internal: Group models in the given collection into an object with
    # 'open', 'locked', and 'pinned' keys.
    #
    # pipeline - The collection to group.
    #
    # Returns an object.
    _groupModels: (pipeline) ->
      defaults = { pinned: [], locked: [], open: [] }
      _.extend(defaults, pipeline.groupBy(@_modelBucket))

    # Determine the name of the model's proper collection.
    #
    # model - A discussion topic model.
    #
    # Returns a string.
    _modelBucket: (model) ->
      return 'pinned' if model.get('pinned')
      return 'locked' if model.get('locked')
      'open'

    # Internal: Move a model from one collection to another.
    #
    # model - The model to transition.
    #
    # Returns nothing.
    moveModel: (model) =>
      view.collection.remove(model) for key, view of @discussions
      @discussions[@_modelBucket(model)].collection.add(model)

  # Start up the page
  router = new DiscussionIndexRouter
  Backbone.history.start()
