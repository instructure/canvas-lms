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
  'jquery.disableWhileLoading'
], (I18n, _, Backbone, Message, MessageCollection, MessageView, MessageListView, MessageDetailView, MessageFormDialog, InboxHeaderView) ->

  class ConversationsRouter extends Backbone.Router

    routes:
      '': 'index'

    messages:
      confirmDelete: I18n.t('confirm.delete_conversation', 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.')

    index: ->
      @_initViews()
      @_attachEvents()

    onSelected: (model) =>
      unless model.get('selected')
        if model.id == @detail.model?.id
          @header.toggleMessageBtns(true)
          delete @detail.model
          return @detail.render()
        return

      @header.toggleMessageBtns(false)
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

    _initViews: ->
      @_initListView()
      @_initDetailView()
      @_initHeaderView()
      @_initComposeDialog()

    _attachEvents: ->
      @list.collection.on('change:selected', @onSelected)
      @header.on('compose',   @onCompose)
      @header.on('reply',     @onReply)
      @header.on('reply-all', @onReplyAll)
      @header.on('delete',    @onDelete)

    _initListView: ->
      @list = new MessageListView
        collection: new MessageCollection
        el: $('.message-list')
      @list.render()
      @list.collection.fetch()

    _initDetailView: ->
      @detail = new MessageDetailView(el: $('.message-detail'))
      @detail.render()

    _initHeaderView: ->
      @header = new InboxHeaderView(el: $('header.panel'))
      @header.render()

    _initComposeDialog: ->
      @compose = new MessageFormDialog() #this, this.canAddNotesFor, folderId: @options.FOLDER_ID)


  window.conversationsRouter = new ConversationsRouter
  Backbone.history.start()
