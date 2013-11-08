define [
  'compiled/collections/GroupUserCollection'
  'Backbone'
], (GroupUserCollection, {Model, Collection}) ->

  source = null
  target = null
  users = null

  module 'GroupUserCollection',
    setup: ->
      group = new Model(id: 1)
      category = new Model()
      category._groups = new Collection([group])
      users = [
        new Model(id: 1, name: "bob", sortable_name: "bob", groupId: null),
        new Model(id: 2, name: "joe", sortable_name: "joe", groupId: null)
      ]
      source = new GroupUserCollection(users, groupId: null)
      source.category = category
      category._unassignedUsers = source
      target = new GroupUserCollection([], groupId: 1)
      target.group = group
      group._users = target

  test "moves user to target group's collection when groupId changes", ->
    users[0].set('groupId', 1)
    equal source.length, 1
    equal target.length, 1

  test "removes user when target group's collection is not yet loaded", ->
    users[0].set('groupId', 2) # not the target
    equal source.length, 1
    equal target.length, 0

