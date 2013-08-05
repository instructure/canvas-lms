define [
  'jquery'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
], ($, GroupView, GroupUsersView, GroupCollection, GroupUserCollection, Group) ->

  view = null
  group = null
  users = null

  module 'GroupView',
    setup: ->
      group = new Group
        id: 42
        name: 'Foo Group'
        members_count: 7
      users = new GroupUserCollection [
        {id: 1, name: "bob", sortable_name: "bob"}
        {id: 2, name: "joe", sortable_name: "joe"}
      ]
      users.loaded = true
      users.loadedAll = true
      group.users = -> users
      groupUsersView = new GroupUsersView {group, collection: users}
      view = new GroupView {groupUsersView, model: group}
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
      view.remove()

  assertContracted = (view) ->
    ok view.$el.hasClass('group-collapsed'), 'expand visible'
    ok not view.$el.hasClass('group-expanded'), 'contract hidden'

  assertExpanded = (view) ->
    ok not view.$el.hasClass('group-collapsed'), 'expand hidden'
    ok view.$el.hasClass('group-expanded'), 'contract visible'

  test 'initial state should be contracted', ->
    assertContracted view

  test 'expand/contract buttons', ->
    view.$('.toggle-group').eq(0).click()
    assertExpanded view
    view.$('.toggle-group').eq(0).click()
    assertContracted view

  test 'renders groupUsers', ->
    ok view.$('.group-user').length

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
