define [
  'ember'
  'compiled/util/round'
  'compiled/grade_calculator'
], (Ember, round, GradeCalculator) ->

  FinalGradeGradesComponent = Ember.Component.extend

    percent: (->
      @get("student.total_percent")
    ).property('student.total_percent','student')

    pointRatio: ( ->
      "#{@get('student.total_grade.score')} / #{@get('student.total_grade.possible')}"
    ).property("student", "weighted_groups")

    letterGrade:(->
      GradeCalculator.letter_grade(@get('gradingStandard'), @get('percent'))
    ).property('gradingStandard', 'percent')

    showGrade: Ember.computed.bool('student.total_grade.possible')

    showPoints:(->
      !!(@get("weighted_groups") or not @get("student.total_grade"))
    ).property("weighted_groups","student.total_grade")

    showLetterGrade: Ember.computed.bool("gradingStandard")
