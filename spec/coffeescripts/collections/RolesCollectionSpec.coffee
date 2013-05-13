define [
  'Backbone'
  'underscore'
  'compiled/models/Role'
  'compiled/collections/RolesCollection'
  'compiled/util/BaseRoleTypes'
], (Backbone,_, Role, RolesCollection) ->
  module 'RolesCollection',
    setup: ->
      @account_id = 2
    teardown: -> 
      @account_id = null

  test "generate the correct url for a collection of roles", 1, -> 
    roles_collection = new RolesCollection null,
      contextAssetString: "account_#{@account_id}"

    equal roles_collection.url(), "/api/v1/accounts/#{@account_id}/roles", "roles collection url"

  test "fetches a collection of roles", 1, -> 
    server = sinon.fakeServer.create()

    role1 = new Role
    role2 = new Role

    roles_collection = new RolesCollection null,
      contextAssetString: "account_#{@account_id}"

    roles_collection.fetch success: => 
      equal roles_collection.size(), 2, "Adds all of the roles to the collection"
  
    server.respond 'GET', roles_collection.url(), [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify([role1, role2])]

    server.restore()

  test "keeps roles in order based on sort order then alphabetically", -> 
    RolesCollection.sortOrder = [
      "AccountMembership"
      "StudentEnrollment"
      "TaEnrollment"
    ]

    roleFirst = new Role 
      base_role_type : "AccountMembership"
      role: 'AccountAdmin'

    roleSecond = new Role 
      base_role_type : "AccountMembership"
      role: 'Another account membership'

    roleThird = new Role 
      base_role_type : "StudentEnrollment"
      role: 'A student Role'

    roleFourth = new Role 
      base_role_type : "StudentEnrollment"
      role: 'B student Role'

    roleFith = new Role 
      base_role_type : "TaEnrollment"
      role: 'A TA role'

    roleCollection = new RolesCollection([roleThird, roleSecond, roleFirst, roleFourth, roleFith])

    equal roleCollection.models[0], roleFirst, "First role is in order"
    equal roleCollection.models[1], roleSecond, "Second role is in order"
    equal roleCollection.models[2], roleThird, "Third role is in order"
    equal roleCollection.models[3], roleFourth, "Forth role is in order"
    equal roleCollection.models[4], roleFith, "Fith role is in order"






