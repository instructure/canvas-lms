define [
  'Backbone'
  'compiled/models/GroupUser'
  'jquery'
], (Backbone, GroupUser, $) ->

  module 'GroupUser',
    setup: ->
      @groupUser = new GroupUser()
      @leaveGroupStub = sinon.stub @groupUser, 'leaveGroup'
      @joinGroupStub = sinon.stub @groupUser, 'joinGroup'
    teardown: ->
      @leaveGroupStub.restore()
      @joinGroupStub.restore()

  test "updates groupId correctly upon save and fires joinGroup and leaveGroup appropriately", ->
    @groupUser.save({'groupId': 777})
    equal @groupUser.get('groupId'), 777
    equal @joinGroupStub.callCount, 1
    ok @joinGroupStub.calledWith 777
    equal @leaveGroupStub.callCount, 0

    @groupUser.save({'groupId': 123})
    equal @groupUser.get('groupId'), 123
    equal @joinGroupStub.callCount, 2
    ok @joinGroupStub.calledWith 123

    @groupUser.save({'groupId': null})
    equal @groupUser.get('groupId'), null
    equal @joinGroupStub.callCount, 2
    equal @leaveGroupStub.callCount, 1