define [
  'ember'
  '../../components/assignment_muter_component'
  '../start_app'
  '../shared_ajax_fixtures'
  'jquery'
], (Ember, AssignmentMuter, startApp, fixtures, $) ->

  {ContainerView, run} = Ember

  fixtures.create()
  mutedAssignment = fixtures.assignment_groups[0].assignments[1]
  unmutedAssignment = fixtures.assignment_groups[0].assignments[0]

  compareIdentity = (assignment, fixture) ->
    equal assignment.muted, fixture.muted, 'muted status'
    equal assignment.id, fixture.id, 'assignment id'


  module 'screenreader_gradebook assignment_muter_component: setup',
    setup: ->
      App = startApp()
      run =>
        @assignment = Ember.copy(mutedAssignment, true)
        @component = App.AssignmentMuterComponent.create(assignment: @assignment)
    teardown: ->
      run =>
        @component.destroy()
        @component = null

  test 'it works', ->
    compareIdentity(@component.get('assignment'), mutedAssignment)

    Ember.run =>
      @assignment = Ember.copy(unmutedAssignment, true)
      @component.setProperties
        assignment: @assignment

    compareIdentity(@component.get('assignment'), unmutedAssignment)