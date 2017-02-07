define [
  'ember'
  'compiled/util/round'
  'jsx/gradebook/GradingSchemeHelper'
], (Ember, round, GradingSchemeHelper) ->

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
      percentage = parseFloat(@get('rawPercent').toPrecision(4))
      GradingSchemeHelper.scoreToGrade(percentage, standard)
    ).property('gradingStandard', 'hasGrade')

    values:(->
      student = @get('student')
      Ember.get student, "assignment_group_#{@get('ag.id')}"
    ).property('ag', 'student', 'student.total_grade')

    points: (->
      values = @get('values')
      "#{round(values.score, round.DEFAULT)} / #{round(values.possible, round.DEFAULT)}"
    ).property('values')

    # This method returns the raw percentage, float errors and all e.g. 54.5 / 100 * 100 will return 54.50000000000001
    # It's use is in any further calculations so we're not using a pre-rounded number.
    rawPercent:(->
      values = @get('values')
      values.score / values.possible * 100
    ).property('values')

    percent:(->
      values = @get('values')
      "#{round((values.score / values.possible)*100, round.DEFAULT)}%"
    ).property('values')

    scoreDetail:(->
      points = @get('points')
      "(#{points})"
    ).property('points')
