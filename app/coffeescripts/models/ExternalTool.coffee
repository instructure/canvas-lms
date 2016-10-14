define [
  'underscore'
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
], (_, {Model}, DefaultUrlMixin) ->

  class ExternalTool extends Model
    @mixin DefaultUrlMixin

    initialize: ->
      super
      delete @url if _.has(@, 'url')

    resourceName: 'external_tools'

    computedAttributes: [
      {
        name: 'custom_fields_string'
        deps: ['custom_fields']
      }
    ]

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/create_tool_with_verification"

    custom_fields_string: ->
      ("#{k}=#{v}" for k,v of @get('custom_fields')).join("\n")

    launchUrl: (launchType, options = {})->
      params = for key, value of options
        "#{key}=#{value}"
      url = "/#{@_contextPath()}/external_tools/#{@id}/resource_selection?launch_type=#{launchType}"
      url = "#{url}&#{params.join('&')}" if params.length > 0
      url

    assetString: () ->
      "context_external_tool_#{@id}"
