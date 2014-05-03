define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Message'
  'compiled/views/conversations/MessageItemView'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, $, _, {View}, Message, MessageItemView, template, noMessage) ->

  class MessageDetailView extends View

    tagName: 'div'

    render: (options = {})->
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
        $template = noMessage(options)
      @$el.html($template)
      @$el.find('.subject').focus()
      this
