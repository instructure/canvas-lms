define [
  'jquery'
  'compiled/views/groups/manage/UnassignedUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
], ($, UnassignedUsersView, AssignToGroupMenu, GroupCollection, GroupUserCollection, Group) ->

  clock = null
  view = null
  groups = null
  users = null

  module 'UnassignedUsersView',
    setup: ->
      clock = sinon.useFakeTimers()
      groups = new GroupCollection [
        new Group name: "a group"
        new Group name: "another group"
      ]
      users = new GroupUserCollection [
        {id: 1, name: "bob", sortable_name: "bob"}
        {id: 2, name: "joe", sortable_name: "joe"}
      ]
      menu = new AssignToGroupMenu
        collection: groups
      view = new UnassignedUsersView
        collection: users
        groupsCollection: groups
        assignToGroupMenu: menu
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
      clock.restore()
      view.remove()
      $('.assign-to-group-menu').remove()

  test 'toggles group class if canAssignToGroup', ->
    groups.pop() # no change yet, because not empty
    ok view.$el.attr('class').indexOf('group-category-empty') == -1

    group = groups.pop()
    ok view.$el.attr('class').indexOf('group-category-empty') >= 0

    groups.push(group)
    ok view.$el.attr('class').indexOf('group-category-empty') == -1

  test 'opens the assignToGroupMenu', ->
    view.$('.assign-to-group').eq(0).click()
    clock.tick(100)
    $menu = $('.assign-to-group-menu').filter(':visible')
    equal $menu.length, 1
    equal $menu.find('.set-group').length, 2
