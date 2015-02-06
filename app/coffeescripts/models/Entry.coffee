####
# TODO: consolidate this into DiscussionEntry
#

define [
  'i18n!discussions'
  'jquery'
  'underscore'
  'Backbone'
  'str/stripTags'
  'jquery.ajaxJSON'
], (I18n, $, _, Backbone, stripTags) ->

  ##
  # Model representing an entry in discussion topic
  class Entry extends Backbone.Model

    defaults:

      ##
      # Attributes persisted with the server
      id: null
      parent_id: null
      message: I18n.t('no_content', 'No Content')
      user_id: null
      read_state: 'read'
      forced_read_state: false
      created_at: null
      updated_at: null
      deleted: false
      attachment: null

      ##
      # Received from API, but not persisted
      replies: []

      ##
      # Client side attributes not persisted with the server
      canAttach: ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH

      # so we can branch for new stuff
      new: false

      highlight: false

    computedAttributes: [
      'canModerate'
      'canReply'
      'hiddenName'
      'speedgraderUrl'
      'inlineReplyLink'
      { name: 'allowsSideComments', deps: ['parent_id', 'deleted'] }
      { name: 'allowsThreadedReplies', deps: ['deleted'] }
      { name: 'showBoxReplyLink', deps: ['allowsSideComments'] }
      { name: 'collapsable', deps: ['replies', 'allowsSideComments', 'allowsThreadedReplies'] }
      { name: 'summary', deps: ['message'] }
    ]

    ##
    # We don't follow backbone's route conventions, a method for each
    # http method, used in `@sync`
    read: ->
     "#{ENV.DISCUSSION.ENTRY_ROOT_URL}?ids[]=#{@get 'id'}"

    create: ->
      @set 'author', ENV.DISCUSSION.CURRENT_USER
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

    toJSON: ->
      json = super
      _.pick json,
        'id'
        'parent_id'
        'message'
        'user_id'
        'read_state'
        'forced_read_state'
        'created_at'
        'updated_at'
        'deleted'
        'attachment'
        'replies'
        'author'

    hiddenName: ->
      if ENV.DISCUSSION.HIDE_STUDENT_NAMES
        isGradersEntry = @get('user_id')+'' is ENV.DISCUSSION.CURRENT_USER.id
        isStudentsEntry = @get('user_id')+'' is ENV.DISCUSSION.STUDENT_ID

        if isGradersEntry
          @get('author').display_name
        else if isStudentsEntry
          I18n.t('this_student', "This Student")
        else
          I18n.t('discussion_participant', "Discussion Participant")

    ##
    # Computed attribute to determine if the entry can be moderated
    # by the current user
    canModerate: ->
      isAuthorsEntry = @get('user_id')+'' is ENV.DISCUSSION.CURRENT_USER.id
      isAuthorsEntry and ENV.DISCUSSION.PERMISSIONS.CAN_MANAGE_OWN or ENV.DISCUSSION.PERMISSIONS.MODERATE

    ##
    # Computed attribute to determine if the entry can be replied to
    # by the current user
    canReply: ->
      return no if @get 'deleted'
      return no unless ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
      yes

    ##
    # Computed attribute to determine if an inlineReplyLink should be
    # displayed for the entry.
    inlineReplyLink: ->
      return yes if ENV.DISCUSSION.THREADED && (@allowsThreadedReplies() || @allowsSideComments())
      no

    ##
    # Only threaded discussions get the ability to reply in an EntryView
    # Directed discussions have the reply form in the EntryCollectionView
    allowsThreadedReplies: ->
      return no if @get 'deleted'
      return no unless ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
      return no if not ENV.DISCUSSION.THREADED
      yes

    allowsSideComments: ->
      return no if @get 'deleted'
      return no unless ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
      return no if ENV.DISCUSSION.THREADED
      return no if @get 'parent_id'
      yes

    showBoxReplyLink: ->
      @allowsSideComments()

    collapsable: ->
      @hasChildren() or
      @allowsSideComments() or
      @allowsThreadedReplies()

    ##
    # Computed attribute
    speedgraderUrl: ->
      # ENV.DISCUSSION.SPEEDGRADER_URL_TEMPLATE will only exist if I have permission to grade
      # and this thing is an assignment
      if ENV.DISCUSSION.SPEEDGRADER_URL_TEMPLATE
        ENV.DISCUSSION.SPEEDGRADER_URL_TEMPLATE.replace /%22:student_id%22/, @get('user_id')

    ##
    # Computed attribute
    summary: ->
      stripTags @get('message')

    ##
    # Not familiar enough with Backbone.sync to do this, using ajaxJSON
    # Also, we can't just @save() because the mark as read api is a different
    # resource altogether
    markAsRead: ->
      @set 'read_state', 'read'
      url = ENV.DISCUSSION.MARK_READ_URL.replace /:id/, @get 'id'
      $.ajaxJSON url, 'PUT'

    markAsUnread: ->
      @set(read_state: 'unread', forced_read_state: true)
      url = ENV.DISCUSSION.MARK_UNREAD_URL.replace /:id/, @get 'id'
      $.ajaxJSON url, 'DELETE', forced_read_state: true

    hasChildren: ->
      @get('replies').length > 0

