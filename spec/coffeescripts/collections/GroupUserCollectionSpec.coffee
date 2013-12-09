define [
  'compiled/collections/GroupUserCollection'
  'compiled/collections/UnassignedGroupUserCollection'
  'compiled/models/GroupCategory'
  'compiled/models/GroupUser'
  'compiled/models/Group'
  'Backbone'
], (GroupUserCollection, UnassignedGroupUserCollection, GroupCategory, GroupUser, Group, {Collection}) ->

  source = null
  target = null
  users = null

  module 'GroupUserCollection',
    setup: ->
      group = new Group(id: 1)
      category = new GroupCategory()
      category._groups = new Collection([group])
      users = [
        new GroupUser(id: 1, name: "bob", sortable_name: "bob", groupId: null),
        new GroupUser(id: 2, name: "joe", sortable_name: "joe", groupId: null)
      ]
      source = new UnassignedGroupUserCollection users, {category}
      category._unassignedUsers = source
      target = new GroupUserCollection null, {group, category}
      target.loaded = true
      group._users = target

  test "moves user to target group's collection when groupId changes", ->
    users[0].set('groupId', 1)
    equal source.length, 1
    equal target.length, 1

  test "removes user when target group's collection is not yet loaded", ->
    users[0].set('groupId', 2) # not the target
    equal source.length, 1
    equal target.length, 0

