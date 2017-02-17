define [
  'jquery'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/GroupDetailView'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
  'helpers/fakeENV'
], ($, GroupView, GroupUsersView, GroupDetailView, GroupCollection, GroupUserCollection, Group, fakeENV) ->

  view = null
  group = null
  users = null

  QUnit.module 'GroupView',
    setup: ->
      fakeENV.setup()
      group = new Group
        id: 42
        name: 'Foo Group'
        members_count: 7
      users = new GroupUserCollection [
        {id: 1, name: "bob", sortable_name: "bob"}
        {id: 2, name: "joe", sortable_name: "joe"}
      ], {group}
      users.loaded = true
      users.loadedAll = true
      group.users = -> users
      groupUsersView = new GroupUsersView {model: group, collection: users}
      groupDetailView = new GroupDetailView {model: group, users}
      view = new GroupView {groupUsersView, groupDetailView, model: group}
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  assertCollapsed = (view) ->
    ok view.$el.hasClass('group-collapsed'), 'expand visible'
    ok not view.$el.hasClass('group-expanded'), 'collapse hidden'

  assertExpanded = (view) ->
    ok not view.$el.hasClass('group-collapsed'), 'expand hidden'
    ok view.$el.hasClass('group-expanded'), 'collapse visible'

  test 'initial state should be collapsed', ->
    assertCollapsed view

  test 'expand/collpase buttons', ->
    view.$('.toggle-group').eq(0).click()
    assertExpanded view
    view.$('.toggle-group').eq(0).click()
    assertCollapsed view

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
    @stub window, 'confirm', -> true

    # when
    view.$('.delete-group').click()
    server.respond()
    # expect
    ok not view.$el.hasClass('hidden'), 'group hidden'

    server.restore()
