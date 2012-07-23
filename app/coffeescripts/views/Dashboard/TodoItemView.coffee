define [
  'Backbone'
  'jst/TodoItemView/grading'
  'jst/TodoItemView/submitting'
], ({View}, grading, submitting) ->

  class TodoItemView extends View

    tagName: 'li'

    className: 'todoItem'

    templates: {grading, submitting}

    initialize: ->
      @template = @templates[@model.get 'type']

