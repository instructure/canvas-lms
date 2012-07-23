define ['Backbone'], ({View, Collection}) ->

  class TodoView extends View

    collectionClass: Collection

    itemView: View

    title: 'No Title'

    listClassName: ''

    els:
      'ul': '$list'

    initialize: ->
      @collection or= new @collectionClass
      @collection.on 'add', @add
      @collection.on 'reset', @reset
      @collection.fetch()

    add: (model) =>
      view = new @itemView {model}
      view.render()
      @$list.prepend view.el

    reset: =>
      @collection.each @add

    template: ->
      """
        <h2>#{@title}</h2>
        <ul class="right-side-list #{@listClassName}"></ul>
      """

