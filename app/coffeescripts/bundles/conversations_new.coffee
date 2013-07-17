require [
  'Backbone'
  'compiled/models/Message'
  'compiled/collections/MessageCollection'
  'compiled/views/conversations/MessageView'
  'compiled/views/conversations/MessageListView'
  'compiled/views/conversations/MessageDetailView'
  'compiled/views/conversations/MessageFormDialog'
  'jquery.disableWhileLoading'
], (Backbone, Message, MessageCollection, MessageView, MessageListView, MessageDetailView, MessageFormDialog) ->

  class ConversationsRouter extends Backbone.Router

    routes:
      '': 'index'

    index: ->
      @_initViews()
      @_attachEvents()

    onSelected: (model) =>
      unless model.get('selected')
        delete @detail.model
        return @detail.render()

      if model.get('messages')
        @selectConversation(model)
      else
        @detail.$el.disableWhileLoading(model.fetch(success: @selectConversation))

    selectConversation: (model) =>
      @detail.model = model
      @detail.render()

    _initViews: ->
      @_initListView()
      @_initDetailView()
      @_initComposeDialog()

    _attachEvents: ->
      @list.collection.on('change:selected', @onSelected)

    _initListView: ->
      @list = new MessageListView
        collection: new MessageCollection
        el: $('.message-list')
      @list.render()
      @list.collection.fetch()

    _initDetailView: ->
      @detail = new MessageDetailView
        el: $('.message-detail')
      @detail.render()

    _initComposeDialog: ->
      @compose = new MessageFormDialog() #this, this.canAddNotesFor, folderId: @options.FOLDER_ID)
      $('.action-compose-message').on 'click', =>
        @compose.show()


  window.conversationsRouter = new ConversationsRouter
  Backbone.history.start()
