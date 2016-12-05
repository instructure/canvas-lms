define [
  'ember'
  'compiled/util/round'
  'jsx/gradebook/GradingSchemeHelper'
  'i18n!sr_gradebook'
], (Ember, round, GradingSchemeHelper, I18n) ->

  FinalGradeGradesComponent = Ember.Component.extend

    percent: (->
      @get("student.total_percent")
    ).property('student.total_percent','student')

    pointRatioDisplay:(->
      I18n.t "final_point_ratio", "%{pointRatio} points", {pointRatio: @get('pointRatio')}
    ).property("pointRatio")

    pointRatio: ( ->
      "#{@get('student.total_grade.score')} / #{@get('student.total_grade.possible')}"
    ).property("weighted_groups", "student.total_grade.score", "student.total_grade.possible")

    letterGrade:(->
      GradingSchemeHelper.scoreToGrade(@get('percent'), @get('gradingStandard'))
    ).property('gradingStandard', 'percent')

    showGrade: Ember.computed.bool('student.total_grade.possible')

    showPoints:(->
      !!(!@get("weighted_groups") && @get("student.total_grade"))
    ).property("weighted_groups","student.total_grade")

    showLetterGrade: Ember.computed.bool("gradingStandard")
