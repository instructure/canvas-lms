define [
  'underscore',
  'Backbone',
  'compiled/models/FeatureFlag'
], (_, Backbone, FeatureFlag) ->

  class FeatureFlagCollection extends Backbone.Collection

    model: FeatureFlag
