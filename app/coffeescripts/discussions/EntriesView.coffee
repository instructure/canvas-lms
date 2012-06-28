define [
  'underscore'
  'jquery'
  'Backbone'
  'compiled/discussions/EntryCollection'
  'compiled/discussions/EntryCollectionView'
  'compiled/discussions/EntryView'
  'compiled/collections/ParticipantCollection'
  'compiled/discussions/MarkAsReadWatcher'
  'jst/discussions/_reply_form'
  'vendor/ui.selectmenu'
], (_, $, Backbone, EntryCollection, EntryCollectionView, EntryView, ParticipantCollection, MarkAsReadWatcher, template, replyForm) ->

  ##
  # View for all of the entries in a topic. TODO: There is some overlap and
  # role confusion between this and TopicView, potential refactor to make
  # their roles clearer (for starters, the Topic model should probably be
  # fetched by the TopicView).
  #
  # events: `onFetchSucess` - Called when the model is successfully fetched
  #
  class EntriesView extends Backbone.View

    events:

      ##
      # Catch-all for delegating entry click events in this view instead
      # of delegating events in every entry view. This way we have one
      # event listener instead of several hundred.
      #
      # Instead of the usual backbone pattern of adding events to delegate
      # in EntryView, add the `data-event` attribute to elements in the
      # view and the method defined will be called on the appropriate
      # EntryView instance.
      #
      # ex:
      #
      #    <div data-event="someMethod">
      #      click to call someMethod on an EntryView instance
      #   </div>
      #
      'click .entry': 'handleEntryEvent'

    ##
    # Initializes a new EntryView
    initialize: ->
      @$el = $ '#discussion_subentries'

      @participants = new ParticipantCollection
      @model.bind 'change:participants', @initParticipants

      @collection = new EntryCollection
      @model.bind 'change:view', @initEntries

      MarkAsReadWatcher.on 'markAsRead', @onMarkAsRead

      @model.fetch success: @onFetchSuccess

    ##
    # Initializes all the entries
    #
    # @api private
    initEntries: (thisView, entries) =>
      @collectionView = new EntryCollectionView
        $el: @$el
        collection: @collection
        showReplyButton: ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
      @collection.reset entries
      @updateFromNewEntries()
      @setUnreadEntries()
      MarkAsReadWatcher.init()

    updateFromNewEntries: ->
      newEntries = @model.get 'new_entries'
      _.each newEntries, (entry) =>
        view = EntryView.instances[entry.id]
        if view
          # update
          view.model.set entry
        else
          # create
          view = EntryView.instances[entry.parent_id] or this
          view.collection.add entry

    ##
    # We don't get the unread state with the initial models, but we do get
    # a list of ids for the unread entries. This fills in the gap
    #
    # @api private
    setUnreadEntries: ->
      unread_entries = @model.get 'unread_entries'
      _.each unread_entries, (id) ->
        EntryView.instances[id].model.set 'read_state', 'unread'

    ##
    # Initializes the participants. This collection is used as a data lookup
    # when since the user information is not stored on the Entry
    #
    # @api private
    initParticipants: (thisView, participants) =>
      @participants.reset participants

    ##
    # Event listener for MarkAsReadWatcher. Whenever an entry is marked as read
    # we remove the entry id from the unread_entries attribute of @model.
    #
    # @api private
    onMarkAsRead: (entry) =>
      unread = @model.get 'unread_entries'
      id = entry.get 'id'
      @model.set 'unread_entries', _.without(unread, id)

    ##
    # Called when the Topic model is successfully returned from the server,
    # triggers `fetchSuccess` so other objects can wait.
    #
    # @api private
    onFetchSuccess: =>
      @model.trigger 'fetchSuccess', @model

    ##
    # Routes events to the appropriate EntryView instance. See comments in
    # `events` block of this file.
    #
    # @api private
    handleEntryEvent: (event) ->
      # get the element and the method to call
      el = $(event.target).closest '[data-event]'
      return unless el.length
      method = el.data 'event'

      # get the EntryView instance ID
      modelEl = $(event.currentTarget)
      id = modelEl.data 'id'

      # call the method from the EntryView, sets the context to the view
      # so you can access everything in the method like it was called
      # from a normal backbone event
      instance = EntryView.instances[id]
      instance[method](event, el)

      # we already handled it, dont let it bubble up to the entries I am nested in
      false
