define [
  'ember'
  'compiled/util/round'
  'compiled/grade_calculator'
], (Ember, round, GradeCalculator) ->

  AssignmentGroupGradesComponent = Ember.Component.extend

    tagName: ''
    ag: null
    student: null
    weightingScheme: null
    gradingStandard: null
    hasGrade: Ember.computed.bool('values.possible')
    hasWeightedGroups: Ember.computed.equal('weightingScheme', 'percent')

    letterGrade:(->
      standard = @get('gradingStandard')
      return null unless standard and @get('hasGrade')
      GradeCalculator.letter_grade standard, @get('percent')
    ).property('gradingStandard', 'hasGrade')

    values:(->
      student = @get('student')
      Ember.get student, "assignment_group_#{@get('ag.id')}"
    ).property('ag', 'student', 'student.total_grade')

    points: (->
      values = @get('values')
      "#{round(values.score, 2)} / #{round(values.possible, 2)}"
    ).property('values')

    percent:(->
      values = @get('values')
      "#{round (values.score / values.possible)*100, 1}%"
    ).property('values')

    scoreDetail:(->
      points = @get('points')
      "(#{points})"
    ).property('points')
