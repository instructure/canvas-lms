define [
  'compiled/views/Filterable'
  'Backbone'
  'compiled/views/CollectionView'
], (Filterable, {Collection, View}, CollectionView) ->

  view = null

  module 'Filterable',
    setup: ->
      class MyCollectionView extends CollectionView
        @mixin Filterable

        template: ->
          """
          <input class="filterable">
          <div class="collectionViewItems"></div>
          """

      collection = new Collection [
        {id: 1, name: "bob"},
        {id: 2, name: "joe"}
      ]
      view = new MyCollectionView {collection, itemView: View}
      view.render()

  test 'hides items that don\'t match the filter', ->
    equal view.$list.children().length, 2
    equal view.$list.children('.hidden').length, 0

    view.$filter.val("b")
    view.$filter.trigger 'input'

    equal view.$list.children().length, 2
    equal view.$list.children('.hidden').length, 1

    view.$filter.val("bb")
    view.$filter.trigger 'input'

    equal view.$list.children().length, 2
    equal view.$list.children('.hidden').length, 2




