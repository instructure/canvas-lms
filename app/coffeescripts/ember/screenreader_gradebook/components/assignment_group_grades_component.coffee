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
      percentage = Math.round(parseInt(@get('percent')), round.DEFAULT)
      GradeCalculator.letter_grade standard, percentage
    ).property('gradingStandard', 'hasGrade')

    values:(->
      student = @get('student')
      Ember.get student, "assignment_group_#{@get('ag.id')}"
    ).property('ag', 'student', 'student.total_grade')

    points: (->
      values = @get('values')
      "#{round(values.score, round.DEFAULT)} / #{round(values.possible, round.DEFAULT)}"
    ).property('values')

    percent:(->
      values = @get('values')
      "#{round((values.score / values.possible)*100, round.DEFAULT)}%"
    ).property('values')

    scoreDetail:(->
      points = @get('points')
      "(#{points})"
    ).property('points')
