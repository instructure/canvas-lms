require [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'compiled/models/Message'
  'compiled/collections/MessageCollection'
  'compiled/views/conversations/MessageView'
  'compiled/views/conversations/MessageListView'
  'compiled/views/conversations/MessageDetailView'
  'compiled/views/conversations/MessageFormDialog'
  'compiled/views/conversations/InboxHeaderView'
  'compiled/util/deparam'
  'compiled/collections/CourseCollection'
  'compiled/collections/FavoriteCourseCollection'
  'jquery.disableWhileLoading'
], (I18n, _, Backbone, Message, MessageCollection, MessageView, MessageListView, MessageDetailView, MessageFormDialog,
 InboxHeaderView, deparam, CourseCollection, FavoriteCourseCollection) ->

  class ConversationsRouter extends Backbone.Router

    routes:
      '': 'index'
      'filter?:state': 'filter'

    messages:
      confirmDelete: I18n.t('confirm.delete_conversation', 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.')

    initialize: ->
      @_initCollections()
      @_initViews()
      @_attachEvents()

    onSelected: (model) =>
      @header.onModelChange(null, @model)
      @model = model
      unless model.get('selected')
        if model.id == @detail.model?.id
          delete @detail.model
          return @detail.render()
        return

      if model.get('messages')
        @selectConversation(model)
      else
        @detail.$el.disableWhileLoading(model.fetch(success: @selectConversation))

    selectConversation: (model) =>
      @header.onModelChange(model, null)
      @detail.model = model
      @detail.render()

    onReply: (message) =>
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

    onDelete: =>
      return unless confirm(@messages.confirmDelete)
      @detail.model.destroy()
      delete @detail.model
      @detail.render()

    onCompose: (e) =>
      @compose.show(null, trigger: $('#compose-btn'))

    index: ->
      @filter('')

    filter: (state) ->
      filters = @filters = deparam(state)
      @header.displayState(filters)
      @selectConversation(null)
      @list.collection.reset()
      @list.collection.setParam('scope', filters.type)
      @list.collection.setParam('filter', @_currentFilter())
      @list.collection.setParam('filter_mode', 'and')
      @list.collection.fetch()
      @compose.setDefaultCourse(filters.course)

    onMarkUnread: =>
      @detail.model.toggleReadState(false)
      @detail.model.save()
      @header.hideMarkUnreadBtn(true)

    onForward: (message) =>
      model = if message
        model = @detail.model.clone()
        model.set 'messages', _.filter model.get('messages'), (m) ->
          m.id == message.id or (_.include(m.participating_user_ids, message.author_id) and m.created_at < message.created_at)
        trigger = $(".message-item-view[data-id=#{message.id}] .al-trigger")
        model
      else
        trigger = $('#admin-btn')
        @detail.model
      @compose.show(model, to: 'forward', trigger: trigger)

    onStarToggle: =>
      @detail.model.toggleStarred()
      @detail.model.save()

    onFilter: (filters) =>
      @navigate('filter?'+$.param(filters), {trigger: true})

    onCourse: (course) =>
      @list.updateCourse(course)

    _initCollections: () ->
      @courses = 
        favorites: new FavoriteCourseCollection()
        all: new CourseCollection()
      @courses.favorites.fetch()

    _initViews: ->
      @_initListView()
      @_initDetailView()
      @_initHeaderView()
      @_initComposeDialog()

    _attachEvents: ->
      @list.collection.on('change:selected', @onSelected)
      @header.on('compose',     @onCompose)
      @header.on('reply',       @onReply)
      @header.on('reply-all',   @onReplyAll)
      @header.on('delete',      @onDelete)
      @header.on('filter',      @onFilter)
      @header.on('course',      @onCourse)
      @header.on('mark-unread', @onMarkUnread)
      @header.on('forward',     @onForward)
      @header.on('star-toggle', @onStarToggle)
      @header.on('search',      @onSearch)
      @compose.on('close',      @onCloseCompose)
      @compose.on('addMessage', @onAddMessage)
      @compose.on('addMessage', @list.updateMessage)
      @compose.on('submitting', @onSubmit)
      @detail.on('reply',       @onReply)
      @detail.on('reply-all',   @onReplyAll)
      @detail.on('forward',     @onForward)

    onSubmit: (dfd) =>
      @detail.$el.disableWhileLoading(dfd)

    onAddMessage: (message) =>
      @detail.addMessage(message)

    _currentFilter: ->
      filter = @searchTokens || []
      filter = filter.concat(@filters.course) if @filters.course
      filter

    onSearch: (tokens) =>
      @list.collection.reset()
      @searchTokens = if tokens.length then tokens else null
      @list.collection.setParam('filter', @_currentFilter())
      @list.collection.fetch()

    _initListView: ->
      @list = new MessageListView
        collection: new MessageCollection
        el: $('.message-list')
      @list.render()

    _initDetailView: ->
      @detail = new MessageDetailView(el: $('.message-detail'))
      @detail.render()

    _initHeaderView: ->
      @header = new InboxHeaderView(el: $('header.panel'), courses: @courses)
      @header.render()

    _initComposeDialog: ->
      @compose = new MessageFormDialog(courses: @courses, folderId: ENV.CONVERSATIONS.ATTACHMENTS_FOLDER_ID)

  window.conversationsRouter = new ConversationsRouter
  Backbone.history.start()
