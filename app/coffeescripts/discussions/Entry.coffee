define [
  'use!underscore'
  'compiled/backbone-ext/Backbone'
  'compiled/util/backbone.multipart.sync'
  'jquery.ajaxJSON'
], (_, Backbone) ->

  ##
  # Model representing an entry in discussion topic
  class Entry extends Backbone.Model

    defaults:

      ##
      # Attributes persisted with the server

      id: null
      parent_id: null
      summary: null
      message: null
      user_id: null
      read_state: 'read'
      created_at: null
      updated_at: null
      deleted: false
      attachment: null

      ##
      # Received from API, but not persisted

      replies: []

      ##
      # Client side attributes not persisted with the server

      parent_cid: null

      # Change this to toggle between collapsed and expanded views
      collapsedView: true

      # Non-threaded topics get no replies, threaded discussions may require
      # people to make an initial post before they can reply to others
      canReply: ENV.DISCUSSION.PERMISSIONS.CAN_REPLY && ENV.DISCUSSION.THREADED

      canAttach: ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH

      # not used, but we'll eventually want to style differently when
      # an entry is "focused"
      focused: false

    computedAttributes: [
      'author'
      'editor'
      'canModerate'
    ]

    ##
    # We don't follow backbone's route conventions, a method for each
    # http method, used in `@sync`
    read: ->
     "#{ENV.DISCUSSION.ENTRY_ROOT_URL}?ids[]=#{@get 'id'}"

    create: ->
      parentId = @get('parent_id')
      if not parentId # i.e. top-level
        ENV.DISCUSSION.ROOT_REPLY_URL
      else
        ENV.DISCUSSION.REPLY_URL.replace /:entry_id/, parentId

    delete: ->
      ENV.DISCUSSION.DELETE_URL.replace /:id/, @get 'id'

    update: ->
      ENV.DISCUSSION.DELETE_URL.replace /:id/, @get 'id'

    sync: (method, model, options = {}) ->
      options.url = @[method]()
      Backbone.sync method, this, options

    parse: (data) ->
      if _.isArray data
        # GET (read) requests send an array O.o
        data[0]
      else
        # POST (create) requests just send the object
        data

    ##
    # Computed attribute to get the author into the model data
    author: ->
      return {} if @get('deleted')
      userId = @get 'user_id'
      if userId is ENV.DISCUSSION.CURRENT_USER.id
        ENV.DISCUSSION.CURRENT_USER
      else
        DISCUSSION.participants.get(userId).toJSON()

    ##
    # Computed attribute to determine if the entry can be moderated
    # by the current user
    canModerate: ->
      isAuthorsEntry = @get('user_id') is ENV.DISCUSSION.CURRENT_USER.id
      isAuthorsEntry or ENV.DISCUSSION.PERMISSIONS.MODERATE

    ##
    # Computed attribute to determine if the entry has an editor
    editor: ->
      editor_id = @get 'editor_id'
      return unless editor_id
      DISCUSSION.participants.get(editor_id).toJSON()

    ##
    # Not familiar enough with Backbone.sync to do this, using ajaxJSON
    # Also, we can't just @save() because the mark as read api is a different
    # resource altogether
    markAsRead: ->
      @set 'read_state', 'read'
      url = ENV.DISCUSSION.MARK_READ_URL.replace /:id/, @get 'id'
      $.ajaxJSON url, 'PUT'

