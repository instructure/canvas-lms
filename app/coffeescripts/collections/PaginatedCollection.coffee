define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  class PaginatedCollection extends Backbone.Collection

    fetchNextPage: (options={}) ->
      throw new Error "can't fetch next page when @nextPageUrl is undefined" unless @nextPageUrl?
      options = _.extend {}, options,
        add: true
        url: @nextPageUrl

      @fetchingNextPage = true
      @trigger 'beforeFetchNextPage'
      @fetch(options).done =>
        @fetchingNextPage = false
        @trigger 'didFetchNextPage', arguments...

    _parsePageLinks: (xhr) ->
      linkHeader = xhr.getResponseHeader('link').split(',')

      # Matches the name of each link: "next," "prev," "first," or "last."
      nameRegex = /rel="([a-z]+)/

      # Matches the full link, e.g. "/api/v1/accounts/1/users?page=1&per_page=15"
      linkRegex = /^<([^>]+)/

      pageRegex = /\Wpage=(\d+)/

      perPageRegex = /\per_page=(\d+)/

      # # Matches only the querystring in the link, e.g. "?page=1&per_page=15"
      # paramsRegex = /(\?[^>]+)/

      # Reduce the link header into a hash.
      links = _.reduce linkHeader, (links, link) ->
        key = link.match(nameRegex)[1]
        val = link.match(linkRegex)[1]
        links[key] = val
        links
      , {}

      @nextPageUrl = links.next
      @totalPages = parseInt(links.last?.match(pageRegex)[1], 10)
      @perPage = parseInt(links.first.match(perPageRegex)[1], 10)

      # useful for dispaying 'nothingToShow' messages
      @atLeastOnePageFetched = true


    parse: (response, xhr) ->
      @_parsePageLinks(xhr)
      super