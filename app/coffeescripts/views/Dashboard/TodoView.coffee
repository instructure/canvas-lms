define [
  'i18n!dashboard'
  'Backbone'
  'compiled/collections/TodoCollection'
  'compiled/views/Dashboard/TodoItemView'
], (I18n, {View, Collection, Model}, TodoCollection, TodoItemView) ->

  class TodoView extends View

    initialize: ->
      @collection or= new TodoCollection
      @collection.on 'add', @addTodo
      @collection.on 'reset', @resetTodos
      @collection.fetch()

    addTodo: (todo) =>
      view = new TodoItemView model: todo
      view.render()
      @$list.prepend view.el

    resetTodos: =>
      @collection.each @addTodo

    render: ->
      @$el.html """
        <h2>#{I18n.t 'todo', 'Todo'}</h2>
        <ul class="todoList nav nav-list"></ul>
      """
      @$list = @$ '.todoList'
      super


