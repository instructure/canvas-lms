define [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, _, {View}, template, noMessage) ->

  class MessageDetailView extends View

    tagName: 'div'

    template: template

    events:
      'click li[data-id]': 'selectMessage'

    render: ->
      if @model
        @$el.html(template(@model.toJSON().conversation))
      else
        @$el.html(noMessage())

    selectMessage: (e) ->
      selectedMessage = $(e.currentTarget)
      messageObject   = _.find(@model.get('messages'), (m) -> m.id == selectedMessage.data('id'))
      messageObject.selected = !messageObject.selected
      selectedMessage.toggleClass('active', messageObject.selected)
