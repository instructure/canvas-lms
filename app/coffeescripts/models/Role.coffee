define [
  'Backbone'
  'underscore'
  'compiled/models/Account'
], ({Model}, _, Account) ->
  class Role extends Model
    initialize: ->
      super

    isNew: ->
      not @get('id')?

    # Method Summary
    #   urlRoot is used in url to generate the a restful url
    #
    # @api override backbone
    urlRoot: -> "/api/v1/accounts/#{ENV.CURRENT_ACCOUNT.account.id}/roles"

    # Method Summary
    #   ResourceName is used by a collection to help determin the url
    #   that should be generated for the resource.
    # @api custom backbone override
    resourceName: 'roles'

    # Method Summary
    #   See backbones explaination of a validate method for in depth 
    #   details but in short, if your return something from validate
    #   there is an error, if you don't, there are no errors. Throw 
    #   in the error object to any validation function you make. It's 
    #   passed by reference dawg.
    # @api override backbone
    validate: (attrs) ->
      errors = {}
      errors unless _.isEmpty errors

    editable: ->
      @get('workflow_state') != 'built_in'
