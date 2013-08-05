define [
  'i18n!conversations'
  'Backbone'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, {View}, template, noMessage) ->

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
      $(e.target).parents('li[data-id]').toggleClass('active')
