define [ '../questions_controller', 'i18n!quiz_statistics' ], (Base, I18n) ->
  Base.extend
    correctResponseRatioLabel: (->
      I18n.t('correct_essay_student_ratio',
        '%{ratio}% of your students received full credit for this question.',
        {
          ratio: Em.Util.round(@get('correctResponseRatio') * 100, 0)
        })
    ).property('correctResponseRatio')

    correctResponseRatio: (->
      participantCount = @get('participantCount')

      if participantCount > 0
        @get('fullCredit') / participantCount
      else
        0
    ).property('fullCredit', 'participantCount')
