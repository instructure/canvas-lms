define [
  'Backbone'
  'underscore'
  'compiled/models/Role'
  'compiled/models/Account'
  'compiled/util/BaseRoleTypes'
  'helpers/fakeENV'
], (Backbone,_, Role, Account, BASE_ROLE_TYPES, fakeENV) ->
  QUnit.module 'RoleModel',
    setup: -> 
      @account = new Account id: 4
      @role = new Role account: @account
      @server = sinon.fakeServer.create()
      fakeENV.setup(CURRENT_ACCOUNT: {account: {id: 3}})

    teardown: ->
      @server.restore()
      @role = null
      @account_id = null
      fakeENV.teardown()

  test 'generates the correct url for existing and non-existing roles', 2, -> 
    equal @role.url(), "/api/v1/accounts/3/roles", "non-existing role url"
    
    @role.fetch success: =>
      equal @role.url(), "/api/v1/accounts/3/roles/1", "existing role url"

    @server.respond 'GET', @role.url(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify({"role": "existingRole", "id": "1", "account" : @account})]
    
