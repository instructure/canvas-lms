define [
  'jquery'
  'compiled/views/groups/manage/UnassignedUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/collections/GroupUserCollection'
  'compiled/models/Group'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, UnassignedUsersView, AssignToGroupMenu, GroupCollection, GroupUserCollection, Group) ->

  clock = null
  view = null
  groups = null
  users = null

  module 'UnassignedUsersView',
    setup: ->
      $('#fixtures').html('<div id="content"></div>')
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
      $('#fixtures').append( view.$el )
                    .append( $('<div />', id: 'content') )

    teardown: ->
      $('#fixtures').empty()
      clock.restore()
      view.remove()
      $('#fixtures').empty()

  test 'opens the assignToGroupMenu', ->
    view.$('.assign-to-group').eq(0).simulate('click')
    clock.tick(100)
    $menu = $('.assign-to-group-menu').filter(':visible')
    equal $menu.length, 1
    equal $menu.find('.set-group').length, 2
