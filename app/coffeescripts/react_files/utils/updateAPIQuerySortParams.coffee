define [
  'underscore'
  'jquery'
  'compiled/util/deparam'
], (_, {param}, deparam) ->

  # if you change which column to order by or wheather to to sort asc or desc,
  # use this to change the api url of the collection
  updateAPIQuerySortParams = (collection, queryParams) ->
    newParams =
      include: ['user']
      per_page: 20
      sort: queryParams.sort || ''
      order: queryParams.order || ''

    oldUrl = collection.url
    [baseUrl, search] = oldUrl.split('?')
    params = _.extend(deparam(search), newParams)
    newUrl = baseUrl + '?' + param(params)
    collection.url = newUrl
    collection.reset() if newUrl isnt oldUrl and !collection.loadedAll