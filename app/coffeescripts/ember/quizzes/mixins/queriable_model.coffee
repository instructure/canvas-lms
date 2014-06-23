define [
  'ember'
  'underscore'
  '../shared/query_parameters'
], ({Mixin}, _, QueryParameters) ->
  # This mixin adds support for providing query parameters to a DS.Model's
  # fetching methods, necessary if you need to side-load different things based
  # on runtime state.
  Mixin.create
    reload: (queryParams) ->
      originalUrl = @get('url')
      originalParams = QueryParameters.extractParameters(originalUrl)
      baseUrl = QueryParameters.extractUrl(originalUrl)
      params = _.extend({}, originalParams, queryParams)

      @set 'url', QueryParameters.composeUrl(baseUrl, params)

      # reload and then restore the url to its original value
      @_super().finally =>
        @set 'url', originalUrl