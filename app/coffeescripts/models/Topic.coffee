####
# TODO: consolidate this into DiscussionTopic
#

define [
  'i18n!discussions'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/util/BackoffPoller'
  'compiled/arr/walk'
  'compiled/arr/erase'
  'jquery.ajaxJSON'
], (I18n, $, {each, extend, values}, Backbone, BackoffPoller, walk, erase) ->

  UNKNOWN_AUTHOR =
    avatar_image_url: null
    display_name: I18n.t 'uknown_author', 'Unknown Author'
    id: null

  class MaterializedDiscussionTopic extends Backbone.Model

    defaults:
      view: []
      entries: []
      new_entries: []
      unread_entries: []
      forced_entries: []
      entry_ratings: {}

    url: ->
      "#{@get 'root_url'}?include_new_entries=1"

    fetch: (options = {}) ->
      loader = new BackoffPoller @url(), (data, xhr) =>
        return 'continue' if xhr.status is 503
        return 'abort' if xhr.status isnt 200
        @set(@parse(data, 200, xhr))
        options.success?(this, data)
        # TODO: handle options.error
        'stop'
      ,
        handleErrors: true
        initialDelay: false
        # we'll abort after about 10 minutes
        baseInterval: 2000
        maxAttempts: 12
        backoffFactor: 1.6
      loader.start()

    markAllAsRead: ->
      $.ajaxJSON ENV.DISCUSSION.MARK_ALL_READ_URL, 'PUT', forced_read_state: false
      @setAllReadState('read')

    markAllAsUnread: ->
      $.ajaxJSON ENV.DISCUSSION.MARK_ALL_UNREAD_URL, 'DELETE', forced_read_state: false
      @setAllReadState('unread')

    setAllReadState: (newReadState) ->
      each @flattened, (entry) ->
        entry.read_state = newReadState

    parse: (data, status, xhr) ->
      @data = data
      # build up entries in @data.entries, mainly because we don't want deleted
      # entries, and deleting them in place messes with our loops
      @data.entries = []
      # a place to do quick lookups to assign parents and other manipulation
      @flattened = {}
      # keep track of this so we can know the root_entry_id since the api
      # doesn't return it to us
      @lastRoot = null
      @participants = {}
      @flattenParticipants()
      walk @data.view, 'replies', @parseEntry
      each @data.new_entries, @parseNewEntry
      walk @data.entries, 'replies', @setEntryRoot
      #@maybeRemove entry for id, entry of @flattened
      delete @lastRoot
      @data

    flattenParticipants: ->
      for participant in @data.participants
        @participants[participant.id] = participant

    setEntryAuthor: (entry) ->
      if entry.user_id?
        entry.author = @participants[entry.user_id]
      else
        entry.author = UNKNOWN_AUTHOR

    setEntryState: (entry) =>
      entry.parent = @flattened[entry.parent_id]

      entry.read_state = 'unread' if entry.id in @data.unread_entries
      entry.forced_read_state = true if entry.id in @data.forced_entries
      entry.rating = @data.entry_ratings[entry.id]

      @setEntryAuthor(entry)

      if entry.editor_id?
        entry.editor = @participants[entry.editor_id]

    parseEntry: (entry) =>
      @setEntryState(entry)

      @flattened[entry.id] = entry

      unless entry.parent
        @data.entries.push entry

      entry

    parseNewEntry: (entry) =>
      @setEntryState(entry)

      if oldEntry = @flattened[entry.id]
        # entry was modified since materialized view was built
        extend(oldEntry, entry)
        return

      @flattened[entry.id] = entry

      parent = @flattened[entry.parent_id]
      entry.parent = parent

      if entry.parent
        (entry.parent.replies ?= []).push entry
      else
        @data.entries.push entry

    setEntryRoot: (entry) =>
      if entry.parent_id?
        entry.root_entry = @lastRoot
        # db field but api doesn't return it, no big deal to add it clientside
        entry.root_entry_id = @lastRoot.id
      else
        @lastRoot = entry

    maybeRemove: (entry) ->
      if entry.deleted and !entry.replies
        erase entry.parent.replies, entry if entry.parent?.replies?
        delete @flattened[entry.id]

