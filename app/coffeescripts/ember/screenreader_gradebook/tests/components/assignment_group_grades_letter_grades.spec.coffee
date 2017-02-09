define [
  'ember'
  '../start_app'
  '../../components/assignment_group_grades_component'
  '../shared_ajax_fixtures'
], (Ember, startApp, AGGrades, fixtures) ->

  {run} = Ember

  originalWeightingScheme = null
  originalGradingStandard = null
  groupScores =
    assignment_group_1:
      possible: 100
      score: 54.5
      submission_count: 1
      submissions: []
      weight: 100

  QUnit.module 'assignment_group_grades_component_letter_grade',
    setup: ->
      fixtures.create()
      App = startApp()
      @component = App.AssignmentGroupGradesComponent.create()
      @component.reopen
        gradingStandard: (->
          originalGradingStandard = this._super
          [["A", 0.80],["B+", 55.5],["B", 54.5],["C", 0.05],["F", 0.00]]
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

  test 'letterGrade', ->
    expected = "C"
    equal @component.get('letterGrade'), expected
