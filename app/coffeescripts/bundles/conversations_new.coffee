require [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Message'
  'compiled/collections/MessageCollection'
  'compiled/views/conversations/MessageView'
  'compiled/views/conversations/MessageListView'
  'compiled/views/conversations/MessageDetailView'
  'compiled/views/conversations/MessageFormDialog'
  'compiled/views/conversations/SubmissionCommentFormDialog'
  'compiled/views/conversations/InboxHeaderView'
  'compiled/util/deparam'
  'compiled/collections/CourseCollection'
  'compiled/collections/FavoriteCourseCollection'
  'compiled/collections/GroupCollection'
  'compiled/behaviors/unread_conversations'
  'jquery.disableWhileLoading'
], (I18n, $, _, Backbone, Message, MessageCollection, MessageView, MessageListView, MessageDetailView, MessageFormDialog, SubmissionCommentFormDialog,
 InboxHeaderView, deparam, CourseCollection, FavoriteCourseCollection, GroupCollection) ->

  class ConversationsRouter extends Backbone.Router

    routes:
      '': 'index'
      'filter=:state': 'filter'

    messages:
      confirmDelete: I18n.t('confirm.delete_conversation', 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.')
      messageDeleted: I18n.t('message_deleted', 'Message Deleted!')

    sendingCount: 0

    initialize: ->
      dfd = @_initCollections()
      @_initViews()
      @_attachEvents()
      dfd.then(@_replyFromRemote) if @_isRemoteLaunch()

    # Public: Pull a value from the query string.
    #
    # name - The name of the query string param.
    #
    # Returns a string value or null.
    param: (name) ->
      regex = new RegExp("#{name}=([^&]+)")
      value = window.location.search.match(regex)
      if value then decodeURIComponent(value[1]) else null

    # Internal: Perform a batch update of all selected messages.
    #
    # event - The event to batch (e.g. 'star' or 'destroy').
    # fn - A function called with each selected message. Used for side-effecting.
    #
    # Returns an array of impacted message IDs.
    batchUpdate: (event, fn = $.noop) ->
      messages = _.map @list.selectedMessages, (message) =>
        fn.call(this, message)
        message.get('id')
      $.ajaxJSON '/api/v1/conversations', 'PUT',
        'conversation_ids[]': messages
        event: event
      @list.selectedMessages = [] if event == 'destroy'
      @list.selectedMessages = [] if event == 'archive'      && @filters.type != 'sent'
      @list.selectedMessages = [] if event == 'mark_as_read' && @filters.type == 'archived'
      @list.selectedMessages = [] if event == 'unstar'       && @filters.type == 'starred'
      messages

    lastFetch: null

    onSelected: (model) =>
      @lastFetch.abort() if @lastFetch
      @header.onModelChange(null, @model)
      @detail.onModelChange(null, @model)
      @model = model
      messages = @list.selectedMessages
      if messages.length == 0
        delete @detail.model
        return @detail.render()
      else if messages.length > 1
        delete @detail.model
        @detail.onModelChange(messages[0], null)
        @detail.render(batch: true)
        @header.onModelChange(messages[0], null)
        @header.toggleReplyBtn(true)
        @header.toggleReplyAllBtn(true)
        @header.hideForwardBtn(true)
        return
      else
        model = @list.selectedMessage()
        if model.get('messages')
          @selectConversation(model)
        else
          @lastFetch = model.fetch(data: {include_participant_contexts: false, include_private_conversation_enrollments: false}, success: @selectConversation)
          @detail.$el.disableWhileLoading(@lastFetch)

    selectConversation: (model) =>
      @header.onModelChange(model, null)
      @detail.onModelChange(model, null)
      @detail.render()

    onSubmissionReply: =>
      @submissionReply.show(@detail.model, trigger: $('#submission-reply-btn'))

    onReply: (message) =>
      if @detail.model.get('for_submission')
        @onSubmissionReply()
      else
        @_delegateReply(message, 'reply')

    onReplyAll: (message) =>
      @_delegateReply(message, 'replyAll')

    _delegateReply: (message, type) ->
      btn = if type == 'reply' then 'reply-btn' else 'reply-all-btn'
      if message
        trigger = $(".message-item-view[data-id=#{message.id}] .#{btn}")
      else
        trigger = $("##{btn}")
      @compose.show(@detail.model, to: type, trigger: trigger, message: message)

    onArchive: =>
      action = if @list.selectedMessage().get('workflow_state') == 'archived' then 'mark_as_read' else 'archive'
      messages = @batchUpdate(action, (m) ->
        newState = if action == 'mark_as_read' then 'read' else 'archived'
        m.set('workflow_state', newState)
        @header.onArchivedStateChange(m)
      )
      if _.include(['inbox', 'archived'], @filters.type)
        @list.collection.remove(messages)
        @selectConversation(null)

    onDelete: =>
      return unless confirm(@messages.confirmDelete)
      messages = @batchUpdate('destroy')
      delete @detail.model
      @list.collection.remove(messages)
      @header.updateUi(null)
      $.flashMessage(@messages.messageDeleted)
      @detail.render()

    onCompose: (e) =>
      @compose.show(null, trigger: $('#compose-btn'))

    index: ->
      @filter('')

    filter: (state) ->
      filters = @filters = deparam(state)
      @header.displayState(filters)
      @selectConversation(null)
      @list.selectedMessages = []
      @list.collection.reset()
      if filters.type == 'submission_comments'
        _.each(['scope', 'filter', 'filter_mode', 'include_private_conversation_enrollments'], @list.collection.deleteParam, @list.collection)
        @list.collection.url = '/api/v1/users/self/activity_stream'
        @list.collection.setParam('asset_type', 'Submission')
        if filters.course
          @list.collection.setParam('context_code', filters.course)
        else
          @list.collection.deleteParam('context_code')
      else
        _.each(['context_code', 'asset_type', 'submission_user_id'], @list.collection.deleteParam, @list.collection)
        @list.collection.url = '/api/v1/conversations'
        @list.collection.setParam('scope', filters.type)
        @list.collection.setParam('filter', @_currentFilter())
        @list.collection.setParam('filter_mode', 'and')
        @list.collection.setParam('include_private_conversation_enrollments', false)
      @list.collection.fetch()
      @compose.setDefaultCourse(filters.course)

    onMarkUnread: =>
      @batchUpdate('mark_as_unread', (m) -> m.toggleReadState(false))

    onMarkRead: =>
      @batchUpdate('mark_as_read', (m) -> m.toggleReadState(true))

    onForward: (message) =>
      model = if message
        model = @detail.model.clone()
        model.handleMessages()
        model.set 'messages', _.filter model.get('messages'), (m) ->
          m.id == message.id or (_.include(m.participating_user_ids, message.author_id) and m.created_at < message.created_at)
        trigger = $(".message-item-view[data-id=#{message.id}] .al-trigger")
        model
      else
        trigger = $('#admin-btn')
        @detail.model
      @compose.show(model, to: 'forward', trigger: trigger)

    onStarToggle: =>
      event    = if @list.selectedMessage().get('starred') then 'unstar' else 'star'
      messages = @batchUpdate(event, (m) -> m.toggleStarred(event == 'star'))
      if @filters.type == 'starred'
        @selectConversation(null) if event == 'unstar'
        @list.collection.remove(messages)

    onFilter: (filters) =>
      @navigate('filter='+$.param(filters), {trigger: true})

    onCourse: (course) =>
      @list.updateCourse(course)

    # Internal: Determine if a reply was launched from another URL.
    #
    # Returns a boolean.
    _isRemoteLaunch: ->
      !!window.location.search.match(/user_id/)

    # Internal: Open and populate the new message dialog from a remote launch.
    #
    # Returns nothing.
    _replyFromRemote: =>
      @compose.show null,
        user:
          id: @param('user_id')
          name: @param('user_name')
        context  : @param('context_id')
        remoteLaunch: true

    _initCollections: () ->
      @courses =
        favorites: new FavoriteCourseCollection()
        all: new CourseCollection()
        groups: new GroupCollection()
      @courses.favorites.fetch()

    _initViews: ->
      @_initListView()
      @_initDetailView()
      @_initHeaderView()
      @_initComposeDialog()
      @_initSubmissionCommentReplyDialog()

    _attachEvents: ->
      @list.collection.on('change:selected', @onSelected)
      @header.on('compose',     @onCompose)
      @header.on('reply',       @onReply)
      @header.on('reply-all',   @onReplyAll)
      @header.on('archive',     @onArchive)
      @header.on('delete',      @onDelete)
      @header.on('filter',      @onFilter)
      @header.on('course',      @onCourse)
      @header.on('mark-unread', @onMarkUnread)
      @header.on('mark-read', @onMarkRead)
      @header.on('forward',     @onForward)
      @header.on('star-toggle', @onStarToggle)
      @header.on('search',      @onSearch)
      @header.on('submission-reply', @onReply)
      @compose.on('close',      @onCloseCompose)
      @compose.on('addMessage', @onAddMessage)
      @compose.on('addMessage', @list.updateMessage)
      @compose.on('newConversations', @onNewConversations)
      @compose.on('submitting', @onSubmit)
      @submissionReply.on('addMessage', @onSubmissionAddMessage)
      @submissionReply.on('submitting', @onSubmit)
      @detail.on('reply',       @onReply)
      @detail.on('reply-all',   @onReplyAll)
      @detail.on('forward',     @onForward)
      @detail.on('star-toggle', @onStarToggle)
      @detail.on('delete',      @onDelete)
      @detail.on('archive',     @onArchive)
      $(document).ready(@onPageLoad)
      $(window).keydown(@onKeyDown)

    onPageLoad: (e) ->
      # we add the top style here instead of in the css because
      # we want to accomodate custom css that changes the height
      # of the header.
      $('#main').css(display: 'block', top: $('#header').height())

    onSubmit: (dfd) =>
      @_incrementSending(1)
      dfd.always =>
        @_incrementSending(-1)

    onAddMessage: (message, conversation) =>
      model = @list.collection.get(conversation.id)
      if model? && model.get('messages')
        message.context_name = model.messageCollection.last().get('context_name')
        model.get('messages').unshift(message)
        model.trigger('change:messages')
        if model == @detail.model
          @detail.render()

    onSubmissionAddMessage: (message, submission) =>
      model = @list.collection.findWhere(submission_id: submission.id)
      if model? && model.get('messages')
        model.get('messages').unshift(message)
        model.trigger('change:messages')
        if model == @detail.model
          @detail.render()

    onNewConversations: (conversations) =>

    _incrementSending: (increment) ->
      @sendingCount += increment
      @header.toggleSending(@sendingCount > 0)

    _currentFilter: ->
      filter = @searchTokens || []
      filter = filter.concat(@filters.course) if @filters.course
      filter

    onSearch: (tokens) =>
      @list.collection.reset()
      @searchTokens = if tokens.length then tokens else null
      if @filters.type == 'submission_comments'
        if @searchTokens and match = @searchTokens[0].match(/^user_(\d+)$/)
          @list.collection.setParam('submission_user_id', match[1])
        else
          @list.collection.deleteParam('submission_user_id')
      else
        @list.collection.setParam('filter', @_currentFilter())
      delete @detail.model
      @list.selectedMessages = []
      @detail.render()
      @list.collection.fetch()

    _initListView: ->
      @list = new MessageListView
        collection: new MessageCollection
        el: $('.message-list')
        scrollContainer: $('.message-list-scroller')
        buffer: 50
      @list.render()

    _initDetailView: ->
      @detail = new MessageDetailView(el: $('.message-detail'))
      @detail.render()

    _initHeaderView: ->
      @header = new InboxHeaderView(el: $('header.panel'), courses: @courses)
      @header.render()

    _initComposeDialog: ->
      @compose = new MessageFormDialog
        courses: @courses
        folderId: ENV.CONVERSATIONS.ATTACHMENTS_FOLDER_ID
        account_context_code: ENV.CONVERSATIONS.ACCOUNT_CONTEXT_CODE

    _initSubmissionCommentReplyDialog: ->
      @submissionReply = new SubmissionCommentFormDialog

    onKeyDown: (e) =>
      nodeName = e.target.nodeName.toLowerCase()
      return if nodeName == 'input' || nodeName == 'textarea'
      ctrl = e.ctrlKey || e.metaKey
      if e.which == 65 && ctrl # ctrl-a
        e.preventDefault()
        @list.selectAll()
        return

  window.conversationsRouter = new ConversationsRouter
  Backbone.history.start()
