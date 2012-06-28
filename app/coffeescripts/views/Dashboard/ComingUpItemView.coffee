define [
  'Backbone'
  'jst/ComingUpItemView/assignment'
  'jst/ComingUpItemView/event'
], ({View}, assignment, event) ->

  class ComingUpItemView extends View

    tagName: 'li'

    className: 'comingUpItem'

    templates:
      Assignment: assignment
      Event: event

    initialize: ->
      @template = @templates[@model.get 'type']

