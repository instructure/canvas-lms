define [
  'jquery'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
], ($, GroupUsersView, AssignToGroupMenu, GroupCollection, GroupUserCollection, Group) ->

  view = null
  groups = null
  users = null

  module 'GroupUsersView',
    setup: ->
      groups = new GroupCollection [
        new Group name: "a group"
        new Group name: "another group"
      ]
      users = new GroupUserCollection [
        {id: 1, name: "bob"}
        {id: 2, name: "joe"}
      ]
      menu = new AssignToGroupMenu
        collection: groups
      view = new GroupUsersView
        collection: users
        groupsCollection: groups
        canAssignToGroup: true
        assignToGroupMenu: menu
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
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
    $menu = $('.assign-to-group-menu').filter(':visible')
    equal $menu.length, 1
    equal $menu.find('.set-group').length, 2
