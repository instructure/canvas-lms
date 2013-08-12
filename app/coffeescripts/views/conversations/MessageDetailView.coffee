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

    render: ->
      super
      if @model
        context   = @model.toJSON().conversation
        $template = $(template(context))
        @model.messageCollection.each (message) ->
          childView = new MessageItemView(model: message).render()
          $template.find('.message-content').append(childView.$el)
      else
        $template = noMessage()
      @$el.html($template)
      this
