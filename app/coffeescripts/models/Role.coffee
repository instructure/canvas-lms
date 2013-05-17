define [
  'Backbone'
  'underscore'
  'compiled/models/Account'
], (Backbone, _, Account) ->
  class Role extends Backbone.Model
    # Method Summary
    #   Each role has an Account model nested in it. When creating 
    #   a new role, run it through and makes sure attributes have 
    #   and account model nested in model.account. It's NOT using
    #   parse because parse sets the id to role in parse (because roles
    #   have 'fake' ids so backbone will work) and when an id is set
    #   when you try to save, it assumes it was all ready created and
    #   does a PUT instead of a POST request. Thus, we don't call parse
    #   we call nestAccountModel.
    # @api backbone override
    initialize: (attributes, options) -> 
      super

      if attributes
        parsedAttributes = @nestAccountModel attributes
        @set parsedAttributes

    # Method Summary
    #   urlRoot is used in url to generate the a restful url. Because 
    #   the "id" is set to the roles name (see parse function), the 
    #   url uses the role name in place of the :id attribute in the url
    #
    #   ie: 
    #      /accounts/:account_id/roles
    #      /accounts/:account_id/roles/:some_role_name
    #
    #   produces
    #      /accounts/1/roles
    #      /accounts/1/roles/StudentAssistant
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
    #   Parse is called when data is set via attributes to the model. 
    #   Because roles might not always have a unique id, we are 
    #   setting the id to be the role name. This takes care of checks
    #   for "isNew()" as well as issues with generating a correct url.
    #   Also, ensure that account is wrapped in a backbone model since
    #   the url relies on it being a backbone model.
    # @api override backbone
    parse: (data) ->
      data.id = data.role if data.role
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
