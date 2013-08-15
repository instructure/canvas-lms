define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/WikiPage'
], (PaginatedCollection, WikiPage) ->

  class WikiPageCollection extends PaginatedCollection
    model: WikiPage

    initialize: ->
      super

      @sortOrders =
        title: 'asc'
        created_at: 'desc'
        updated_at: 'desc'
      @setSortField 'title'

      # remove the front_page indicator on all other models when one is set
      @on 'change:front_page', (model, value) =>
        # only change other models if one of the models is being set to true
        return if !value

        for m in @filter((m) -> !!m.get('front_page'))
          m.set('front_page', false) if m != model

    sortByField: (sortField, sortOrder=null) ->
      @setSortField sortField, sortOrder
      @fetch()

    setSortField: (sortField, sortOrder=null) ->
      throw "#{sortField} is not a valid sort field" if @sortOrders[sortField] == undefined

      # toggle the sort order if no sort order is specified and the sort field is the current sort field
      if !sortOrder && @currentSortField == sortField
        sortOrder = if @sortOrders[sortField] == 'asc' then 'desc' else 'asc'

      @currentSortField = sortField
      @sortOrders[@currentSortField] = sortOrder if sortOrder

      @setParams
        sort: @currentSortField
        order: @sortOrders[@currentSortField]

      @trigger 'sortChanged', @currentSortField, @sortOrders
