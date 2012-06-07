define [
  'i18n!dashboard'
  'Backbone'
  'compiled/collections/TodoCollection'
  'compiled/views/Dashboard/TodoItemView'
], (I18n, {View, Collection, Model}, TodoCollection, TodoItemView) ->

  class TodoView extends View

    els:
      '.to-do-list': '$list'

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

    template: ->
      """
        <h2>#{I18n.t 'todo', 'Todo'}</h2>
        <ul class="right-side-list to-do-list"></ul>
      """

