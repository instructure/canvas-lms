define ['Backbone'], ({Model}) ->

  class ExternalTool  extends Model
    resourceName: 'external_tools'

    computedAttributes: [
      {
        name: 'custom_field_string'
        deps: ['custom_fields']
      }
    ]

    custom_field_string: ->
      ("#{k}=#{v}" for k,v of @get('custom_fields')).join("\n")
