define [
  'underscore',
  'Backbone',
  'compiled/models/FeatureFlag'
], (_, Backbone, FeatureFlag) ->

  class FeatureFlagCollection extends Backbone.Collection

    model: FeatureFlag

    fetch: (options = {}) ->
      options.data = _.extend per_page: 20, options.data || {}
      super options
