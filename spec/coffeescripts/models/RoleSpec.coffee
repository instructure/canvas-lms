define [
  'Backbone'
  'underscore'
  'compiled/models/Role'
  'compiled/models/Account'
  'compiled/util/BaseRoleTypes'
], (Backbone,_, Role, Account, BASE_ROLE_TYPES) ->
  module 'RoleModel',
    setup: -> 
      @account = new Account id: 4
      @role = new Role account: @account
      @server = sinon.fakeServer.create()

    teardown: -> 
      @server.restore()
      @role = null
      @account_id = null

  test 'the id gets set to the role name when role is created', 1, ->
    @role.fetch success: =>
      equal @role.get('id'), "existingRole", "Role id should equal the roles name" 

    @server.respond 'GET', @role.url(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify({"role": "existingRole"})]

  test 'generates the correct url for existing and non-existing roles', 2, -> 
    equal @role.url(), "/api/v1/accounts/#{@account.get('id')}/roles", "non-existing role url"
    
    @role.fetch success: =>
      equal @role.url(), "/api/v1/accounts/#{@account.get('id')}/roles/existingRole", "existing role url"

    @server.respond 'GET', @role.url(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify({"role": "existingRole", "account" : @account})]
    
