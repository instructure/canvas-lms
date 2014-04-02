define [ 'ember' ], ({$}) ->
  EXTRACTOR = /[\?|\&]([\w|\[|\]]+\=([^\?\&]+))/g

  # A group of helpers for dealing with query parameters in URLs.

  {
    # Serialize an object of query parameters into a URL string.
    #
    # @param [String] url
    #   The (base) url without any query parameters. See #extractUrl for
    #   stripping the url.
    #
    # @param [Object] queryParams
    #   The query parameters you want to append.
    #
    # @return [String]
    #   The URL with the query parameters.
    composeUrl: (url, queryParams) ->
      return url unless queryParams
      [ url, decodeURIComponent($.param(queryParams)) ].join('?')

    # Extract all query parameters specified in a URL string.
    #
    # Only primitive/scalar values and arrays of them are supported:
    #
    #   - scalars: "?page=10" -> { page: '10' }
    #   - arrays: "?key[]=foo&key[]=bar" -> { key: [ 'foo', 'bar' ] }
    #
    # @return [Object] The map of the extracted query parameters.
    #
    # @example
    #   url = 'http://www.google.com?page=1&include[]=images&include[]=source'
    #   params = QueryParameters.extract(url)
    #   console.debug(params) // => { page: 1, include: [ 'images', 'source' ]}
    extractParameters: (queryString) ->
      queryString ||= ''
      fragments = queryString.match(EXTRACTOR) || []
      fragments.reduce((params, entry) ->
        entry = entry.substr(1) # discard leading ? or &
        [ k, v ] = entry.split('=')
        isArray = k.substr(-2) == '[]'

        if isArray
          k = k.substr(0, k.length-2)
          params[k] = params[k] || []
          params[k].push(v)
        else
          params[k] = v

        params
      , {})

    # @return [String] The URL without the query parameters.
    extractUrl: (queryString) ->
      queryString ||= ''
      queryString.replace(/\?[^=]+=.*$/, '')
  }