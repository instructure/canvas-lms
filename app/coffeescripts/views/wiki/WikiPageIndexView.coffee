define [
  'compiled/views/PaginatedCollectionView'
  'compiled/views/wiki/WikiPageIndexItemView'
  'jst/wiki/WikiPageIndex'
  'jquery'
  'jquery.disableWhileLoading'
], (PaginatedCollectionView, itemView, template,$) ->

  class WikiPageIndexView extends PaginatedCollectionView
    initialize: ->
      super
      @sortOrders =
        title: 'asc'
        created_at: 'desc'
        updated_at: 'desc'

      # Next sort order to use when column is clicked
      @nextSortOrders =
        title: 'desc'
        created_at: 'desc'
        updated_at: 'desc'

    @mixin
      el: '#content'
      template: template
      itemView: itemView

      events:
        'click .new_page': 'createNewPage'
        'click .canvas-sortable-header-row a[data-sort-field]': 'sort'

    sort: (event) ->
      currentTarget = $(event.currentTarget)
      currentSortField = @collection.options.params?.sort or "title"
      newSortField = $(event.currentTarget).data 'sort-field'

      if currentSortField is newSortField
        @sortOrders[newSortField] = if @sortOrders[newSortField] is 'asc' then 'desc' else 'asc'
        @nextSortOrders[newSortField] = if @sortOrders[newSortField] is 'asc' then 'desc' else 'asc'
        currentTarget.data 'sort-order',@sortOrders[newSortField]

      @collection.setParam 'sort',newSortField
      @collection.setParam 'order',@sortOrders[newSortField]
      @$el.disableWhileLoading @collection.fetch().then ->
        $('.canvas-sortable-header-row a[data-sort-field="' + newSortField + '"]').focus()

    createNewPage: (ev) ->
      ev?.preventDefault()

      alert('This will eventually create a new page')

    toJSON: ->
      json = super
      json.fetched = @fetched
      json.sortField = @collection.options.params?.sort or "title"
      json.sortOrders = @sortOrders
      json.nextSortOrders = @nextSortOrders
      json
