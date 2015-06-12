define [
  'Backbone'
  'jst/conversations/contextMessage'
], ({View}, template) ->

  class ContextMessageView extends View

    tagName: 'li'

    template: template

    events:
      'click a.context-more': 'toggle'
      'click .delete-btn': 'triggerRemoval'

    initialize: ->
      super
      @model.set(isCondensable: @model.get('body').length > 180)
      @model.set(isCondensed: true)

    toJSON: ->
      json = super
      if json.isCondensable && json.isCondensed
        json.body = json.body.substr(0, 180).replace(/\W\w*$/, '')
      json

    toggle: (e) ->
      e.preventDefault()
      @model.set(isCondensed: !@model.get('isCondensed'))
      @render()
      @$('a').focus()

    triggerRemoval: ->
      @model.trigger("removeView", { view: @ })
