define [
  'jquery'
  'compiled/util/deparam'
], ({param}, deparam) ->

  SortableMixin =

    subject: ->
      @props.model or @props.collection

    handleSortChange: ->
      url = new URL(window.location)
      params = deparam url.search.replace(/^\?/, '')
      params.sort = @subject().get('sort')
      params.order = @subject().get('order')
      url.search = param(params)
      window.history.replaceState(null, null, url.toString())

  SortableMixin.componentWillReceiveProps =
  SortableMixin.componentWillMount = ->
    queryParams = deparam window.location.search.replace(/^\?/, '')
    @subject().set('sort', queryParams.sort) if 'sort' of queryParams
    @subject().set('order', queryParams.order) if 'order' of queryParams
    @subject().on('change:sort change:order', @handleSortChange, this)

  SortableMixin

