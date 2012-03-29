define [
  'jquery'
  'use!underscore'
  'compiled/backbone-ext/Backbone'
  'compiled/util/backbone.multipart.sync'
  'jquery.ajaxJSON'
], ($, _, Backbone) ->

  ##
  # Model representing an entry in discussion topic
  class Entry extends Backbone.Model

    defaults:

      ##
      # Attributes persisted with the server

      id: null
      parent_id: null
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
      # false because we expand everything on load
      collapsedView: false

      canAttach: ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH

      # not used, but we'll eventually want to style differently when
      # an entry is "focused"
      focused: false

    computedAttributes: [
      'author'
      'editor'
      'canModerate'
      'allowsSideComments'
      'hideRepliesOnCollapse'
      { name: 'canReply', deps: ['parent_id'] }
      { name: 'summary', deps: ['message'] }
    ]

    ##
    # We don't follow backbone's route conventions, a method for each
    # http method, used in `@sync`
    read: ->
     "#{ENV.DISCUSSION.ENTRY_ROOT_URL}?ids[]=#{@get 'id'}"

    create: ->
      parentId = @get 'parent_id'
      if parentId is null # i.e. top-level
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
    # Only threaded discussions get the ability to reply in an EntryView
    # Directed discussions have the reply form in the EntryCollectionView
    canReply: ->
      return false unless ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
      return true if ENV.DISCUSSION.THREADED
      false

    ##
    # Computed attribute to determine if the entry has an editor
    editor: ->
      editor_id = @get 'editor_id'
      return unless editor_id
      DISCUSSION.participants.get(editor_id).toJSON()

    ##
    # Computed attribute
    summary: ->
      @escapeDiv ||= $('<div/>')
      @escapeDiv.html(@get('message')).text()

    ##
    # Shows the reply form at the bottom of all side comments
    allowsSideComments: ->
      deleted = @get 'deleted'
      not ENV.DISCUSSION.THREADED and
      ENV.DISCUSSION.PERMISSIONS.CAN_REPLY and
      @get('parent_id') is null and # root entry
      not deleted

    ##
    # Computed attribute. In side_comment discussions we hide the replies
    # on collapse
    hideRepliesOnCollapse: ->
      not ENV.DISCUSSION.THREADED and
      # TODO: have @get('root_entry') instead of this check all over the place
      @get('parent_id') is null and
      @get('replies').length > 0

    ##
    # Not familiar enough with Backbone.sync to do this, using ajaxJSON
    # Also, we can't just @save() because the mark as read api is a different
    # resource altogether
    markAsRead: ->
      @set 'read_state', 'read'
      url = ENV.DISCUSSION.MARK_READ_URL.replace /:id/, @get 'id'
      $.ajaxJSON url, 'PUT'

