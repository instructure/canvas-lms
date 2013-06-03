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
