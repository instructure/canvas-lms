define [
  'Backbone'
  'compiled/models/Group'
  'compiled/models/GroupUser'
  'compiled/models/GroupCategory'
  'jquery'
], (Backbone, Group, GroupUser, GroupCategory, $) ->

  QUnit.module 'GroupUser',
    setup: ->
      @groupUser = new GroupUser
        category: new GroupCategory
      @leaveGroupStub = @stub @groupUser, 'leaveGroup'
      @joinGroupStub = @stub @groupUser, 'joinGroup'

  test "updates group correctly upon save and fires joinGroup and leaveGroup appropriately", ->
    group1 = new Group(id: 777)
    @groupUser.save({'group': group1})
    equal @groupUser.get('group'), group1
    equal @joinGroupStub.callCount, 1
    ok @joinGroupStub.calledWith group1
    equal @leaveGroupStub.callCount, 0

    group2 = new Group(id: 123)
    @groupUser.save({'group': group2})
    equal @groupUser.get('group'), group2
    equal @joinGroupStub.callCount, 2
    ok @joinGroupStub.calledWith group2

    @groupUser.save({'group': null})
    equal @groupUser.get('group'), null
    equal @joinGroupStub.callCount, 2
    equal @leaveGroupStub.callCount, 1
