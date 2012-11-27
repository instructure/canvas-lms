####
# TODO: consolidate this into DiscussionTopic
#

define [
  'i18n!discussions'
  'underscore'
  'Backbone'
  'compiled/util/BackoffPoller'
  'compiled/arr/walk'
  'compiled/arr/erase'
], (I18n, {each}, Backbone, BackoffPoller, walk, erase) ->

  UNKOWN_AUTHOR =
    avatar_image_url: null
    display_name: I18n.t 'uknown_author', 'Unknown Author'
    id: null

  class MaterializedDiscussionTopic extends Backbone.Model

    defaults:
      view: []
      entries: []
      new_entries: []
      unread_entries: []

    url: ENV.DISCUSSION.ROOT_URL + '?include_new_entries=1'

    fetch: (options = {}) ->
      loader = new BackoffPoller @url, (data, xhr) =>
        return 'continue' if xhr.status is 503
        return 'abort' if xhr.status isnt 200
        @set(@parse(data, 200, xhr))
        options.success?(this, data)
        # TODO: handle options.error, perhaps with Backbone.wrapError
        'stop'
      ,
        handleErrors: true
        initialDelay: false
        # we'll abort after about 10 minutes
        baseInterval: 2000
        maxAttempts: 12
        backoffFactor: 1.6
      loader.start()

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
      #@maybeRemove entry for id, entry of @flattened
      delete @lastRoot
      @data

    flattenParticipants: ->
      for participant in @data.participants
        @participants[participant.id] = participant

    parseEntry: (entry) =>
      @flattened[entry.id] = entry
      parent = @flattened[entry.parent_id]
      entry.parent = parent
      entry.read_state = 'unread' if entry.id in @data.unread_entries

      if entry.user_id?
        entry.author = @participants[entry.user_id]
      else
        entry.author = UNKOWN_AUTHOR

      if entry.editor_id?
        entry.editor = @participants[entry.user_id]

      if entry.parent_id?
        entry.root_entry = @lastRoot
        # db field but api doesn't return it, no big deal to add it clientside
        entry.root_entry_id = @lastRoot.id
      else
        @lastRoot = entry
        @data.entries.push entry

      entry

    parseNewEntry: (entry) =>
      @flattened[entry.id] = entry
      parent = @flattened[entry.parent_id]
      if parent?
        (parent.replies ?= []).push entry
        entry.parent = parent
        parent = parent.parent while parent.parent
        entry.root_entry = parent
        entry.root_entry_id = parent.id
      else
        @data.entries.push entry

    maybeRemove: (entry) ->
      if entry.deleted and !entry.replies
        erase entry.parent.replies, entry if entry.parent?.replies?
        delete @flattened[entry.id]

