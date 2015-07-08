define [
  'ember'
  '../start_app'
  '../../components/assignment_group_grades_component'
  '../shared_ajax_fixtures'
], (Ember, startApp, AGGrades, fixtures) ->

  {run} = Ember

  fixtures.create()

  originalWeightingScheme = null
  originalGradingStandard = null
  groupScores =
    assignment_group_1:
      possible: 1000.111
      score: 85.115
      submission_count: 10
      submissions: []
      weight: 90


  module 'assignment_group_grades_component',
    setup: ->
      App = startApp()
      @component = App.AssignmentGroupGradesComponent.create()
      @component.reopen
        gradingStandard: (->
          originalGradingStandard = this._super
          [["A", 0.50],["C", 0.05],["F", 0.00]]
        ).property()
        weightingScheme: (->
          originalWeightingScheme = this._super
          "percent"
        ).property()
      run =>
        @assignment_group = Ember.copy(fixtures.assignment_groups, true).findBy('id', '1')
        @student = Ember.Object.create Ember.copy groupScores
        @component.setProperties
          student: @student
          ag: @assignment_group


    teardown: ->
      run =>
        @component.destroy()
        App.destroy()


  test 'values', ->
    deepEqual @component.get('values'), groupScores.assignment_group_1

  test 'points', ->
    expected = "85.12 / 1000.11"
    equal @component.get('points'), expected

  test 'percent', ->
    expected = "8.5%"
    equal @component.get('percent'), expected

  test 'letterGrade', ->
    expected = "C"
    equal @component.get('letterGrade'), expected

  test 'scoreDetail', ->
    expected = "(85.12 / 1000.11)"
    equal @component.get('scoreDetail'), expected
