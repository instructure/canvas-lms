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
      @header.onModelChange(model, @model)
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
      @detail.model = model
      @detail.render()

    onReply: =>
      messages = @detail.model.get('messages')
      @compose.show(_.find(messages, (m) -> m.selected) or messages[0])

    onReplyAll: =>
      # TODO: passing the conversation model here, but @compose.show() doesn't
      # know what to do with it. we need to get the autocomplete working in the
      # modal.
      @compose.show(@detail.model)

    onDelete: =>
      return unless confirm(@messages.confirmDelete)
      @detail.model.destroy()
      delete @detail.model
      @detail.render()

    onCompose: (e) =>
      @compose.show()

    onCloseCompose: (e) =>
      @header.focusCompose()

    index: ->
      @filter('')

    filter: (state) ->
      filters = @filters = deparam(state)
      @header.displayState(filters)
      @selectConversation(null)
      @list.collection.reset()
      @list.collection.setParam('scope', filters.type)
      filter = @_currentFilter()
      @list.collection.setParam('filter', @_currentFilter())
      @list.collection.fetch()
      @compose.setDefaultCourse(filters.course)

    onMarkUnread: =>
      @detail.model.toggleReadState(false)
      @detail.model.save()
      @header.hideMarkUnreadBtn(true)

    onForward: =>
      # TODO: do something with these options/come up with a better way to
      # specify options. forwarding requires that context and subject be
      # the same as the original message and not changeable. 'to' field
      # should be empty
      @compose.show(@detail.model, 'disabled': ['context', 'subject'])

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
      @header.on('search',      @onSearch)
      @compose.on('close',      @onCloseCompose)

    _currentFilter: ->
      return @searchTokens if @searchTokens
      return "course_#{@filters.course}" if @filters.course
      ''

    onSearch: (tokens) =>
      @list.collection.reset()
      # commenting this out for now because multiple filters don't work.
      # tokens.push("course_#{@courseFilter}") if @courseFilter
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
      @compose = new MessageFormDialog(courses: @courses) #this, this.canAddNotesFor, folderId: @options.FOLDER_ID)

  window.conversationsRouter = new ConversationsRouter
  Backbone.history.start()
