define [
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/models/Group'
  'compiled/models/GroupUser'
], (AssignToGroupMenu, GroupCollection, Group, GroupUser) ->

  view = null
  user = null

  module 'AssignToGroupMenu',
    setup: ->
      user = new GroupUser(id: 1, name: "bob", groupId: null)
      groups = new GroupCollection [
        new Group id: 1, name: "a group"
      ]
      view = new AssignToGroupMenu
        collection: groups
        model: user
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
      view.remove()

  test "updates the user's groupId", ->
    equal user.get('groupId'), null
    $link = view.$('.set-group')
    equal $link.length, 1
    $link.click()
    equal user.get('groupId'), 1


