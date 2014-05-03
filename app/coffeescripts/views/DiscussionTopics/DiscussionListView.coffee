define [
  'jquery'
  'underscore'
  'compiled/views/CollectionView'
  'jst/DiscussionTopics/discussionList'
  'compiled/views/DiscussionTopics/DiscussionView'
  'jqueryui/draggable'
  'jqueryui/sortable'
], ($, _, CollectionView, template, itemView) ->

  class DiscussionListView extends CollectionView
    # Public: Template function (discussionList)
    template: template

    # Public: Discussion item view (DiscussionView)
    itemView: itemView

    # Internal: Default option values
    defaults:
      showSpinner: true
      showMessage: false
      sortable:    false

    # Public: If true, display loading spinner
    @optionProperty 'showSpinner'

    # Public: If true, show 'no discussions' message
    @optionProperty 'showMessage'

    # Public: The title to display as the collapsible header.
    @optionProperty 'title'

    # Public: The DOM ID to assign to this.el.
    @optionProperty 'listId'

    # Public: Turn on sorting for this list.
    @optionProperty 'sortable'

    # Public: Turn on drag-and-drop for this list.
    @optionProperty 'draggable'

    # Public: Allow dragging to this element (should be a CSS selector).
    @optionProperty 'destination'

    # Public: Default spinner display options
    spinnerOptions:
      color: '#333'
      length: 5
      radius: 6
      width: 2

    # Public: Default jQuery sortable options
    sortOptions:
      tolerance: 'pointer'

    # Public: Default jQuery draggable options
    dragOptions:
      helper: 'clone'
      opacity: 0.75
      revert: 'invalid'
      revertDuration: 0
      zIndex: 100

    dropOptions:
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    events:
      'click .al-trigger': 'onAdminClick'

    # Public: Render this view.
    #
    # Returns this.
    render: ->
      super
      @_cacheElements()
      @_toggleNoContentMessage()
      @_initSort() if @options.sortable
      @$el.data('view', this) unless @$el.data('view')
      if @options.showSpinner then @_startLoader() else @_stopLoader()
      this

    renderItem: (model) =>
      super
      @_initDrag(model.view) if @options.draggable

    # Public: Determine if the collection is empty or has no visible elements.
    #
    # Returns boolean.
    isEmpty: ->
      @collection.isEmpty() or @collection.all((m) -> m.get('hidden'))

    # Public: Create JSON to be passed to the view.
    #
    # Returns object.
    toJSON: ->
      _.extend({}, ENV, @options)

    # Internal: Attach events to this view's collection.
    #
    # Returns nothing.
    attachCollection: ->
      @collection.on('change:hidden', @_toggleNoContentMessage)
      @collection.on('fetched:last',  @_onFetchedLast)
      @collection.on('addSync', @_onAddSync) # custom event after saving pinned and locked
      super

    # Internal: Handle clicks on admin gear menu.
    #
    # e - Event object.
    #
    # Returns nothing.
    onAdminClick: (e) ->
      e.preventDefault()

    # Internal: Display spinner loading graphic.
    #
    # Returns nothing.
    _startLoader: ->
      spinner = new Spinner(@spinnerOptions)
      spinner.spin(@$loader.show()[0])

    # Internal: Stop spinner loading graphic.
    #
    # Returns nothing.
    _stopLoader: ->
      @$loader.empty().hide()

    # Internal: Store DOM element references for later use.
    #
    # Returns nothing.
    _cacheElements: ->
      @$loader      = @$el.find('.loader')
      @$noContent   = @$el.find('.no-content')

    # Internal: Toggle the display of the 'no discussions' message.
    #
    # Returns nothing.
    _toggleNoContentMessage: =>
      @$noContent.toggle(@isEmpty()) if @options.showMessage

    # Internal: Update view when collection is finished loading.
    #
    # Returns nothing.
    _onFetchedLast: =>
      @options.showSpinner = false
      @options.showMessage = true
      @_stopLoader()
      @_toggleNoContentMessage()
      # reset to render the whole sorted colleciton now
      @collection.reset(@collection.models)

    # Internal: Enable sorting of the this view's discussions.
    #
    # Returns nothing.
    _initSort: ->
      return unless ENV.permissions.moderate
      @$list.sortable(_.extend({}, @sortOptions))
      @$list.on('sortupdate', @_updateSort)
      $(@options.destination)
        .droppable(_.extend({}, @dropOptions))
        .on('drop', @_onDrop)

    # Internal: On a user's sort action, update the sort order on the server.
    #
    # e - Event object.
    # ui - jQueryUI object.
    #
    # Returns nothing.
    _updateSort: (e, ui) =>
      model = @collection.get(ui.item.data('id'))
      return unless model?.get('pinned')
      @_fixNullPositions().done =>
        @_moveToAfter(model, @collection.at(ui.item.index() - 1))

      # FF 15+ will also fire a click event on the dropped object,
      # and we want to eat that. This is hacky.
      # http://forum.jquery.com/topic/jquery-ui-sortable-triggers-a-click-in-firefox-15
      model.set('preventClick', true)
      setTimeout =>
        model.set('preventClick', false)
      , 0

    # We have a lot of null positions on prod, and they're null when first dragged in.
    _fixNullPositions: () ->
      dfd = $.Deferred().resolve()
      # This chains the updates so they're sent serially, then resolves when the last completes.
      @collection.reduce((dfd, model) =>
        return dfd if model.get('position')?
        dfd.pipe(_.partial(@_moveToBottom, model))
      , dfd)

    _moveToBottom: (model) =>
      last = _.last(@collection.filter((x) -> x.get('position')?))
      return if model == last
      @_moveToAfter(model, last)

    _moveToAfter: (model, sibling) ->
      position = if sibling then sibling.get('position') + 1 else 1
      @_insertAtPosition(model, position)
      model.updateOneAttribute('position_at', position, wait: true)

    # this applies server-side logic to neighboring models
    # see https://github.com/swanandp/acts_as_list/blob/master/lib/acts_as_list/active_record/acts/list.rb
    _insertAtPosition: (model, position) ->
      oldPosition = model.get('position')
      addToPosition = (number, model) ->
        model.set('position', model.get('position') + number)
      incr = _.partial(addToPosition, 1)
      decr = _.partial(addToPosition, -1)

      if oldPosition
        if oldPosition < position # moving model forward
          @collection.filter((x) -> oldPosition < x.get('position') <= position).forEach(decr)
        else if position < oldPosition # moving model backward
          @collection.filter((x) -> position <= x.get('position') < oldPosition).forEach(incr)
      else
        @collection.filter((x) -> x.get('position') >= position).forEach(incr)
      model.set('position', position)
      @collection.sort()

    # Internal: Enable drag/drop on a list item and the list given in
    # @options.destination.
    #
    # view - The child itemView to enable dragging on.
    #
    # Returns nothing.
    _initDrag: (view) ->
      throw new Error('must have destination') unless @options.destination
      return unless ENV.permissions.moderate
      view.$el.draggable(_.extend({}, @dragOptions))
      $(@options.destination)
        .droppable(_.extend({}, @dropOptions))
        .on('drop', @_onDrop)

    # Internal: Handle drop events by pinning/unpinning the topic.
    #
    # e - Event object.
    # ui - jQuery UI object.
    #
    # Returns nothing.
    _onDrop: (e, ui) =>
      model = @collection.get(ui.draggable.data('id'))
      return unless model
      [newGroup, currentGroup] = [$(e.currentTarget).data('view'), this]
      pinned = !!newGroup.options.pinned
      locked = !!newGroup.options.locked
      model.updateBucket(pinned: pinned, locked: locked)

    _onAddSync: (model) =>
      return unless @options.sortable
      @_fixNullPositions()
