define [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'compiled/models/Message'
  'compiled/views/conversations/MessageItemView'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, _, {View}, Message, MessageItemView, template, noMessage) ->

  class MessageDetailView extends View

    tagName: 'div'

    addMessage: (message) =>
      message.context_name = @model.messageCollection.last().get('context_name')
      @model.get('messages').unshift(message)
      @model.trigger('change:messages')
      @render()

    render: ->
      super
      if @model
        context   = @model.toJSON().conversation
        $template = $(template(context))
        @model.messageCollection.each (message) =>
          message.set('conversation_id', context.id) unless message.get('conversation_id')
          childView = new MessageItemView(model: message).render()
          $template.find('.message-content').append(childView.$el)
          @listenTo(childView, 'reply',     => @trigger('reply', message))
          @listenTo(childView, 'reply-all', => @trigger('reply-all', message))
          @listenTo(childView, 'forward',   => @trigger('forward', message))
      else
        $template = noMessage()
      @$el.html($template)
      this
