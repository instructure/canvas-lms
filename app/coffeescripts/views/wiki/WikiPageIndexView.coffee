define [
  'compiled/views/PaginatedCollectionView'
  'compiled/views/wiki/WikiPageIndexItemView'
  'jst/wiki/WikiPageIndex'
], (PaginatedCollectionView, itemView, template) ->

  class WikiPageIndexView extends PaginatedCollectionView
    @mixin
      el: '#content'
      template: template
      itemView: itemView

      events:
        'click .new_page': 'createNewPage'

    createNewPage: (ev) ->
      ev?.preventDefault()

      alert('This will eventually create a new page')

    toJSON: ->
      json = super
      json.fetched = @fetched
      json
