define [
  'compiled/collections/GroupCategoryUserCollection'
  'compiled/models/GroupUser'
  'compiled/views/groups/manage/UnassignedUsersView'
  'jquery'
], (GroupCategoryUserCollection,
    GroupUser,
    UnassignedUsersView,
    $) ->

  server = null
  waldo = null
  users = null
  view = null

  sendResponse = (method, url, json)->
    server.respond method, url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(json)]

  module 'UnassignedUsersView',
    setup: ->
      server = sinon.fakeServer.create()
      waldo = new GroupUser id: 4, name: "Waldo"
      users = new GroupCategoryUserCollection
      view = new UnassignedUsersView
        collection: users
        groupId: 777
      users.reset([
        new GroupUser(id: 1, name: "Frank Herbert"),
        new GroupUser(id: 2, name: "Neal Stephenson"),
        new GroupUser(id: 3, name: "John Scalzi"),
        waldo
      ])
      view.$el.appendTo($(document.body))

    teardown: ->
      server.restore()
      view.remove()

  test "updates the user's groupId and removes from unassigned collection", ->
    equal waldo.get('groupId'), null
    $links = view.$('.assign-to-group')
    equal $links.length, 4

    $waldoLink = $links.last()
    $waldoLink.click()
    sendResponse 'POST', waldo.createMembershipUrl(777), {}
    equal waldo.get('groupId'), 777

    ok not users.contains(waldo)