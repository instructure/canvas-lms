define [
  'compiled/util/mixin'
  'underscore'
], (mixin, _) ->

  ##
  # Mixin to make your (Paginated)CollectionView filterable on the client
  # side. Just put an <input class="filterable> in your template, mix in
  # this mixin, and you're good to go.
  #
  # Filterable simple hides the item views in the DOM, keeping stuff nice
  # and fast (no need to fetch from the server, no need to re-render
  # anything)
  mixin {},

    els:
      '.filterable': '$filter'
      '.no-results': '$noResults'

    defaults:
      filterColumns: ['name']

    afterRender: ->
      @$filter.on 'input', => @setFilter @$filter.val()
      @$filter.trigger 'input'

    setFilter: (@filter) ->
      for model in @collection.models
        model.trigger 'filterOut', @filterOut(model)
      # show a "no results" message if there are items but they are all
      # filtered out
      @$noResults.toggleClass 'hidden', @collection.length and not @$list.children(':visible').length

    attachItemView: (model, view) ->
      filterView = (filtered) ->
        view.$el.toggleClass 'hidden', filtered
      model.on 'filterOut', filterView
      filterView @filterOut(model)

    ##
    # Return whether or not the model (and its view) should be hidden
    # based on the current filter
    filterOut: (model) ->
      return false if not @filter
      return false if not @options.filterColumns.length
      return false if _.any @options.filterColumns, (col) =>
        model.get(col).indexOf(@filter) >= 0
      true

