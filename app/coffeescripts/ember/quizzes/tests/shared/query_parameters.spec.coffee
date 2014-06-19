define ['../../shared/query_parameters'], (QueryParameters) ->
  module 'QueryParameters'

  jsonEqual = (a, b) ->
    strictEqual JSON.stringify(a), JSON.stringify(b)

  test '#composeUrl: it adds a scalar parameter', ->
    equal QueryParameters.composeUrl('/items', { page: 1 }), '/items?page=1'
  
  test '#composeUrl: it adds an array parameter', ->
    url = QueryParameters.composeUrl('/items', {
      types: [ 'fruit', 'vegetables']
    })

    equal url, '/items?types[]=fruit&types[]=vegetables'

  test '#composeUrl: it adds a mix of scalar and array parameters', ->
    url = QueryParameters.composeUrl('/items', {
      page: 1,
      types: [ 'fruit', 'vegetables']
    })

    equal url, '/items?page=1&types[]=fruit&types[]=vegetables'

  test '#extractParameters: it extracts nothing', ->
    jsonEqual QueryParameters.extractParameters(''), {}
    jsonEqual QueryParameters.extractParameters('/items'), {}
    jsonEqual QueryParameters.extractParameters('/items?'), {}
    jsonEqual QueryParameters.extractParameters('/items?page'), {}
    jsonEqual QueryParameters.extractParameters('/items?page='), {}
    jsonEqual QueryParameters.extractParameters('/items?page=&'), {}

  test '#extractParameters: it extracts a scalar', ->
    params = QueryParameters.extractParameters('/items?page=1')
    jsonEqual params, { page: '1' }

  test '#extractParameters: it extracts an array', ->
    params = QueryParameters.extractParameters('/items?types[]=fruit&types[]=vegetables')
    jsonEqual params, { types: [ 'fruit', 'vegetables' ] }
  
  test '#extractParameters: it extracts a mix of scalars and arrays', ->
    params = QueryParameters.extractParameters('/items?page=1&types[]=fruit&types[]=vegetables')
    jsonEqual params, {
      page: '1',
      types: [ 'fruit', 'vegetables' ]
    }

  test '#extractUrl: removes a single parameter', ->
    baseUrl = QueryParameters.extractUrl('/items?page=1')
    strictEqual baseUrl, '/items'

  test '#extractUrl: removes multiple parameters', ->
    baseUrl = QueryParameters.extractUrl('/items?page=1&page_size=20')
    strictEqual baseUrl, '/items'
