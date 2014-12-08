define [
  'Backbone'
  'underscore'
  'compiled/models/Account'
], ({Model}, _, Account) ->
  class Role extends Model
    # Method Summary
    #   Set the attributes as well as the Account model. Note that we
    #   don't use parse, because it sets the model as being not new.
    #   Backbone keys off of isNew() to know if it should do a PUT vs.
    #   POST.
    # @api backbone override
    initialize: (attributes, options) ->
      super

      if attributes
        @set @nestAccountModel(attributes)

    isNew: ->
      not @get('id')?

    # Method Summary
    #   urlRoot is used in url to generate the a restful url
    #
    # @api override backbone
    urlRoot: -> "/api/v1/accounts/#{@get('account').get('id')}/roles" 

    # Method Summary
    #   ResourceName is used by a collection to help determin the url
    #   that should be generated for the resource.
    # @api custom backbone override
    resourceName: 'roles'

    # Method Summary 
    #   Expects data to have data.account object that will be used to
    #   create a new model. The new model replaces the old account 
    #   object.
    # @api private
    nestAccountModel: (data) -> 
      data.account = new Account data.account
      data

    # Method Summary
    #   When we get data from the server, flag the model as not new and
    #   make sure the account is set up correctly
    # @api override backbone
    parse: (data) ->
      data = @nestAccountModel(data)
      data

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
