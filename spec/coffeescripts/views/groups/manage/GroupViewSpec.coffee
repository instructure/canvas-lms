define [
  'jquery'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
], ($, GroupView, GroupUsersView, GroupCollection, GroupUserCollection, Group) ->

  view = null
  groups = null
  users = null

  module 'GroupView',
    setup: ->
      groups = new GroupCollection [
        new Group
          id: 42
          name: 'Foo Group'
          members_count: 7
      ]
      users = new GroupUserCollection [
        {id: 1, name: "bob"}
        {id: 2, name: "joe"}
      ]
      view = new GroupView
        model: groups.at 0
        groupUsersView: new GroupUsersView
          collection: users
          groupsCollection: groups
          canAssignToGroup: true
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
      view.remove()

  assertContracted = (view) ->
    ok not view.$('.expand-group').hasClass('hidden'), 'expand visible'
    ok view.$('.contract-group').hasClass('hidden'), 'contract hidden'
    ok view.groupUsersView.$el.hasClass('hidden'), 'users hidden'

  assertExpanded = (view) ->
    ok view.$('.expand-group').hasClass('hidden'), 'expand hidden'
    ok not view.$('.contract-group').hasClass('hidden'), 'contract visible'
    ok not view.groupUsersView.$el.hasClass('hidden'), 'users visible'

  test 'initial state should be contracted', ->
    assertContracted view

  test 'expand/contract buttons', ->
    view.$('.expand-group').click()
    assertExpanded view
    view.$('.contract-group').click()
    assertContracted view

  test 'renders groupUsers', ->
    ok view.$('.groupUser').length

  test 'removes the group after successful deletion', ->
    url = "/api/v1/groups/#{view.model.get('id')}"
    server = sinon.fakeServer.create()
    server.respondWith url, [
      200
      'Content-Type': 'application/json'
      JSON.stringify {}
    ]
    confirmStub = sinon.stub window, 'confirm'
    confirmStub.returns true

    # when
    view.$('.delete-group').click()
    server.respond()
    # expect
    ok not view.$el.hasClass('hidden'), 'group hidden'

    server.restore()
    confirmStub.restore()
