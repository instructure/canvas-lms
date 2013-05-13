define [
  'compiled/views/courses/roster/CreateUsersView'
  'compiled/models/CreateUserList'
  'helpers/assertions'
], (CreateUsersView, CreateUserList, assert) ->

  view = null
  server = null

  module 'CreateUsersView',
    setup: ->
      server = sinon.fakeServer.create()
      server.respondWith("POST", "/read",
        [200, { "Content-Type": "application/json" }, JSON.stringify({
          users: [{address: 'joe@joe.com', name: null, type: 'email'}],
          errored_users: [],
          duplicates: []
        })])
      server.respondWith("POST", "/update",
        [200, { "Content-Type": "application/json" }, JSON.stringify([
          enrollment: {
            name: 'joe@joe.com'
            email: 'joe@joe.com'
            section: 'MWF'
          }
        ])])
      view = new CreateUsersView
        trigger: false
        title: 'test'
        model: new CreateUserList
          sections: [
            {id: 1, name: 'MWF'}
            {id: 2, name: 'TTh'}
          ]
          roles: [
            {label: 'Teacher', name: 'TeacherEnrollment', manageable_by_user: true}
            {label: 'Student', name: 'StudentEnrollment', manageable_by_user: true}
            {label: 'Fake',    name: 'Fake',              manageable_by_user: false}
          ]
          readURL: '/read'
          updateURL: '/update'
      $('#fixtures').append view.$el
      view.open()

    teardown: ->
      server.restore()
      view.remove()

  addUserText = ->
    view.$textarea.val "joe@joe.com"

  goToStep2 = ->
    $('#next-step').click()
    server.respond()

  goToStep3 = ->
    $('#createUsersAddButton').click()
    server.respond()

  assertVerifiedUsers = ->
    ok $('#create-users-verified').html().match('joe@joe.com'), 'verified users matched'

  assertEnrolledUsers = ->
    ok $('#create-users-results').html().match('joe@joe.com'), 'enrolled users matched'

  assertStepVisible = (step) ->
    assert.isVisible $("#create-users-step-#{step}")

  startOver = ->
    view.$('.createUsersStartOver').click()

  startOverFrd = ->
    view.$('.createUsersStartOverFrd').click()

  assertTextareaValue = (text) ->
    equal view.$textarea.val(), text, 'textarea matches text'

  test 'moves through the steps', ->
    assertStepVisible 1
    addUserText()
    goToStep2()
    assertStepVisible 2
    assertVerifiedUsers()
    goToStep3()
    assertStepVisible 3
    assertEnrolledUsers()
    view.close()

  test 'starts over on step 2', ->
    addUserText()
    goToStep2()
    assertStepVisible 2
    startOver()
    assertStepVisible 1
    assertTextareaValue 'joe@joe.com'
    view.close()

  test 'starts over on step 3', ->
    addUserText()
    goToStep2()
    goToStep3()
    assertStepVisible 3
    startOverFrd()
    assertStepVisible 1
    assertTextareaValue ''

  test 'resets data on close and reopen', ->
    addUserText()
    assertTextareaValue 'joe@joe.com'
    view.close()
    view.open()
    assertTextareaValue ''

