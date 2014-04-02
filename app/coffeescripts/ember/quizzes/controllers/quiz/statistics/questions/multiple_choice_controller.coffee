define [
  '../questions_controller'
  'underscore'
  'i18n!quiz_statistics'
], (Base, _, I18n) ->
  Base.extend
    correctStudentRatioLabel: (->
      I18n.t('correct_student_ratio',
        '%{ratio}% of your students correctly answered this question.',
        {
          ratio: Math.round(@get('correctStudentRatio') * 100)
        })
    ).property('correctStudentRatio')

    correctStudentRatio: (->
      values = @get('responseValues')
      correctAnswer = _.findWhere @get('answers'), { correct: true }

      unless correctAnswer
        return 0

      id = "#{correctAnswer.id}"
      _.where(values, (v) -> "#{v}" == id).length / values.length
    ).property('answers', 'responseValues')