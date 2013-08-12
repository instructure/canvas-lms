define [
  'compiled/collections/GroupCategoryUserCollection'
  'compiled/models/GroupUser'
  'compiled/views/groups/manage/AddUnassignedMenu'
  'jquery'
], (GroupCategoryUserCollection,
    GroupUser,
    AddUnassignedMenu,
    $) ->

  clock = null
  server = null
  waldo = null
  users = null
  view = null

  sendResponse = (method, url, json)->
    server.respond method, url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(json)]

  module 'AddUnassignedMenu',
    setup: ->
      clock = sinon.useFakeTimers()
      server = sinon.fakeServer.create()
      waldo = new GroupUser id: 4, name: "Waldo", sortable_name: "Waldo"
      users = new GroupCategoryUserCollection
      users.setParam 'search_term', 'term'
      view = new AddUnassignedMenu
        collection: users
      view.groupId = 777
      users.reset([
        new GroupUser(id: 1, name: "Frank Herbert", sortable_name: "Herbert, Frank"),
        new GroupUser(id: 2, name: "Neal Stephenson", sortable_name: "Stephenson, Neal"),
        new GroupUser(id: 3, name: "John Scalzi", sortable_name: "Scalzi, John"),
        waldo
      ])
      view.$el.appendTo($(document.body))

    teardown: ->
      clock.restore()
      server.restore()
      view.remove()

  test "updates the user's groupId and removes from unassigned collection", ->
    equal waldo.get('groupId'), null
    $links = view.$('.assign-user-to-group')
    equal $links.length, 4

    $waldoLink = $links.last()
    $waldoLink.click()
    sendResponse 'POST', waldo.createMembershipUrl(777), {}
    equal waldo.get('groupId'), 777

    ok not users.contains(waldo)
