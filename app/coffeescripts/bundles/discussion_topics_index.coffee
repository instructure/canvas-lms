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
        open:   I18n.t('discussions',         'Discussions')
        locked: I18n.t('closed_for_comments', 'Closed for Comments')
        pinned: I18n.t('pinned_discussions',  'Pinned Discussions')
      help:
        title: I18n.t('ordered_by_recent_activity', 'Ordered by Recent Activity')
      toggleMessage: I18n.t('toggle_message', 'toggle discussion visibility')

    # Public: Routes to respond to.
    routes:
      '': 'index'

    initialize: ->
      @discussions =
        open: @_createListView 'open',
          comparator: 'dateComparator'
          draggable: true
          destination: '.pinned.discussion-list, .locked.discussion-list'
        locked: @_createListView 'locked',
          comparator: 'dateComparator'
          destination: '.pinned.discussion-list, .open.discussion-list'
          draggable: true
          locked: true
        pinned: @_createListView 'pinned',
          comparator: 'positionComparator'
          destination: '.open.discussion-list, .locked.discussion-list'
          sortable: true
          pinned: true

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
      pipeline.fetch(data: {order_by: 'recent_activity', per_page: 50})
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
        destination: options.destination
        draggable: !!options.draggable
        itemViewOptions: _.extend(options, pinnable: ENV.permissions.moderate)
        listID: "#{type}-discussions"
        locked: !!options.locked
        pinnable: ENV.permissions.moderate
        pinned: !!options.pinned
        sortable: !!options.sortable
        title: @messages.lists[type]
        titleHelp: (if _.include(['open', 'locked'], type) then @messages.help.title else null)
        toggleMessage: @messages.toggleMessage

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
      @_sortCollection(models)
      setTimeout((-> collection.fetch(page: 'next')), 0) if collection.urls.next

    # Internal: Handle the last page of discussion topic results, propagating
    # the event down to all of the filtered collections.
    #
    # Returns nothing.
    _onPipelineEnd: =>
      view.collection.trigger('fetched:last') for key, view of @discussions
      unless @discussions.pinned.collection.length or ENV.permissions.moderate
        @discussions.pinned.$el.remove()

      if @discussions.pinned.collection.length and !@discussions.open.collection.length and !ENV.permissions.moderate
        @discussions.open.$el.remove()

    # Internal: Sort the given collection into the open, locked, and pinned
    # collections of topics.
    #
    # pipeline - The collection to filter.
    #
    # Returns nothing.
    _sortCollection: (pipeline) ->
      group = @_groupModels(pipeline)
      # add silently and just render whole sorted collection once all the pages have been fetched
      @discussions[key].collection.add(group[key], silent: true) for key of group

    # Internal: Group models in the given collection into an object with
    # 'open', 'locked', and 'pinned' keys.
    #
    # pipeline - The collection to group.
    #
    # Returns an object.
    _groupModels: (pipeline) ->
      defaults = { pinned: [], locked: [], open: [] }
      _.extend(defaults, _.groupBy(pipeline, @_modelBucket))

    # Determine the name of the model's proper collection.
    #
    # model - A discussion topic model.
    #
    # Returns a string.
    _modelBucket: (model) ->
      if model.attributes
        return 'pinned' if model.get('pinned')
        return 'locked' if model.get('locked') || (model.get('locked_for_user') && !model.get('lock_info')['unlock_at']?)
      else
        return 'pinned' if model.pinned
        return 'locked' if model.locked || (model.locked_for_user && !model.lock_info['unlock_at']?)
      'open'

    # Internal: Move a model from one collection to another.
    #
    # model - The model to transition.
    #
    # Returns nothing.
    moveModel: (model) =>
      bucket = @discussions[@_modelBucket(model)].collection
      return if bucket == model.collection
      model.collection.remove(model)
      bucket.add(model)

  # Start up the page
  @router = new DiscussionIndexRouter
  Backbone.history.start()
