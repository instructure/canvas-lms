define [
  'underscore',
  'Backbone',
  'compiled/collections/PaginatedCollection'
  'compiled/models/FeatureFlag'
], (_, Backbone, PaginatedCollection, FeatureFlag) ->

  class FeatureFlagCollection extends PaginatedCollection

    model: FeatureFlag

    fetchAll: ->
      @fetch(success: @fetchNext)

    fetchNext: =>
      if @canFetch 'next'
        @fetch(page: 'next', success: @fetchNext)
      else
        @trigger('finish')

    fetch: (options = {}) ->
      options.data = _.extend per_page: 20, options.data || {}
      super options
