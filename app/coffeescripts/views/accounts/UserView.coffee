define [
  'Backbone'
  'jst/accounts/user'
], (Backbone, template) ->

  class UserView extends Backbone.View

    tagName: 'tr'

    className: 'rosterUser al-hover-container'

    template: template

    events:
      'click': 'click'

    attach: ->
      @model.collection.on 'selectedModelChange', @changeSelection

    click: (e) =>
      e.preventDefault()
      @model.collection.trigger('selectedModelChange', @model)

    changeSelection: (u) =>
      if u == @model
        setTimeout((() => @$el.addClass('selected')), 0)

