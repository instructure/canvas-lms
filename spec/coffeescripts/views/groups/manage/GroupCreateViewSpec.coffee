define [
  'jquery'
  'compiled/models/GroupCategory'
  'compiled/models/Group'
  'compiled/views/groups/manage/GroupCreateView'
  'helpers/fakeENV'
], ($, GroupCategory, Group, GroupCreateView, fakeENV) ->

  view = null
  groupCategory = null
  group = null

  QUnit.module 'GroupCreateView',
    setup: ->
      fakeENV.setup()
      group = new Group
        id: 42
        name: 'Foo Group'
        members_count: 7
      groupCategory = new GroupCategory()
      view = new GroupCreateView({groupCategory: groupCategory, model: group})
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'renders join level in add group dialog for student organized group categories', ->
    view.groupCategory.set('role': 'student_organized')
    view.render()
    $group_join_level_select = $('#group_join_level')
    equal $group_join_level_select.length, 1

  test 'does not render join level in add group dialog for non student organized group categories', ->
    $group_join_level_select = $('#group_join_level')
    equal $group_join_level_select.length, 0

  QUnit.module 'GroupCreateView with blank fields',
    setup: ->
      fakeENV.setup()
      group = new Group
      groupCategory = new GroupCategory()
      view = new GroupCreateView({groupCategory: groupCategory, model: group})
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'set focus on the group edit save button', ->
    view.setFocusAfterError()
    equal document.activeElement, $("#groupEditSaveButton")[0], "Active element"

  ### fails sporadically on jenkins
  test 'editing group should change name', ->
    url = "/api/v1/groups/#{view.model.get('id')}"
    new_name = 'Newly changed name'
    server = sinon.fakeServer.create()
    server.respondWith url, [
      200
      'Content-Type': 'application/json'
      JSON.stringify {
        id: 42
        name: new_name}
    ]
    # verify it opens with the current group name displayed
    equal $('#group_name').val(), group.get('name')
    # set a new name
    $('#group_name').val(new_name)
    $(".group-edit-dialog button[type=submit]").click()
    server.respond()

    equal group.get('name'), new_name
  ###
