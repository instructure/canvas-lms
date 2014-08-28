define [
  'jquery'
  'compiled/views/courses/roster/InvitationsView'
  'compiled/models/RosterUser'
  'helpers/assertions'
], ($, InvitationsView, RosterUser, assert) ->

  view = null
  server = null

  module 'InvitationsView',

    buildView = (enrollment)->
      model = new RosterUser( enrollments: [enrollment] )
      model.currentRole = 'student'
      view = new InvitationsView(model: model)

    test 'knows when invitation is pending', ->
      enrollment = {id: 1, role: 'student', enrollment_state: 'invited'}
      buildView enrollment
      equal view.invitationIsPending(), true

    test 'knows when invitation is not pending', ->
      enrollment = {id: 1, role: 'student', enrollment_state: 'accepted'}
      buildView enrollment
      equal view.invitationIsPending(), false
