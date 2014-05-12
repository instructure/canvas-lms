define [
  '../questions_controller'
  'i18n!quiz_statistics'
], (Base, I18n) ->
  Base.extend
    correctResponseRatioLabel: (->
      I18n.t('correct_response_ratio',
        '%{ratio}% of your students correctly answered this question.',
        {
          ratio: Math.round(@get('correctResponseRatio') * 100)
        })
    ).property('correctResponseRatio')