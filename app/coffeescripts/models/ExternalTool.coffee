define [
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
], ({Model}, DefaultUrlMixin) ->

  class ExternalTool extends Model
    @mixin DefaultUrlMixin

    resourceName: 'external_tools'

    computedAttributes: [
      {
        name: 'custom_field_string'
        deps: ['custom_fields']
      }
    ]

    urlRoot: -> @_defaultUrl()

    custom_field_string: ->
      ("#{k}=#{v}" for k,v of @get('custom_fields')).join("\n")

    launchUrl: (launchType, options = {})->
      params = for key, value of options
        "#{key}=#{value}"
      url = "/#{@_contextPath()}/external_tools/#{@id}/resource_selection?launch_type=#{launchType}"
      url = "#{url}&#{params.join('&')}" if params.length > 0
      url
