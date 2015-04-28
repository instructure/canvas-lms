define [
  'jquery'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/models/Group'
  'compiled/models/GroupUser'
  'compiled/models/GroupCategory'
], ($, AssignToGroupMenu, GroupCollection, Group, GroupUser, GroupCategory) ->

  view = null
  user = null

  module 'AssignToGroupMenu',
    setup: ->
      groupCategory = new GroupCategory
      user = new GroupUser(id: 1, name: "bob", group: null, category: groupCategory)
      groups = new GroupCollection [
        new Group id: 1, name: "a group"
      ], {category: groupCategory}
      view = new AssignToGroupMenu
        collection: groups
        model: user
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test "updates the user's group", ->
    equal user.get('group'), null
    $link = view.$('.set-group')
    equal $link.length, 1
    $link.click()
    equal user.get('group').id, 1
