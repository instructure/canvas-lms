define [
  'Backbone'
  'compiled/str/splitAssetString'
], (Backbone, splitAssetString) ->

  class WikiPage extends Backbone.Model
    resourceName: 'pages'

    parse: (response, options) ->
      response.id = response.url
      response

    toJSON: ->
      json = super

      assetString = this.collection?.contextAssetString || ENV.context_asset_string
      resourceName = this.collection?.resourceName || this.resourceName
      if json.url && assetString && resourceName
        [contextType, contextId] = splitAssetString assetString
        json.htmlUrl = "/#{contextType}/#{contextId}/#{resourceName}/#{json.url}"

      json
