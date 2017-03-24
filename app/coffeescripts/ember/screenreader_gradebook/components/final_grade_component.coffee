define [
  'ember'
  'compiled/util/round'
  'jsx/gradebook/GradingSchemeHelper'
  'i18n!sr_gradebook'
], (Ember, round, GradingSchemeHelper, I18n) ->

  FinalGradeGradesComponent = Ember.Component.extend

    percent: (->
      percent = @get("student.total_percent")
      I18n.n(percent, percentage: true)
    ).property('student.total_percent','student')

    pointRatioDisplay:(->
      I18n.t "final_point_ratio", "%{pointRatio} points", {pointRatio: @get('pointRatio')}
    ).property("pointRatio")

    pointRatio: ( ->
      "#{I18n.n @get('student.total_grade.score')} / #{I18n.n @get('student.total_grade.possible')}"
    ).property("weighted_grades", "student.total_grade.score", "student.total_grade.possible")

    letterGrade:(->
      percent = @get("student.total_percent")
      GradingSchemeHelper.scoreToGrade(percent, @get('gradingStandard'))
    ).property('gradingStandard', 'percent')

    showGrade: Ember.computed.bool('student.total_grade.possible')

    showPoints:(->
      !!(!@get("weighted_grades") && @get("student.total_grade"))
    ).property("weighted_grades","student.total_grade")

    showLetterGrade: Ember.computed.bool("gradingStandard")
