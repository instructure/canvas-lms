define [
  'Backbone'
  'compiled/models/ExternalFeed'
  'compiled/str/splitAssetString'
], (Backbone, ExternalFeed, splitAssetString) ->

  class ExternalFeedCollection extends Backbone.Collection

    model: ExternalFeed
