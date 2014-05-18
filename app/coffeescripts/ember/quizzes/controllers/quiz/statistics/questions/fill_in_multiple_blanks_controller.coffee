define [
  '../questions_controller'
  'i18n!quiz_statistics'
], (Base, I18n) ->
  Base.extend
    answers: Em.computed.alias('ratioCalculator.answerPool')

    # @property [Object] activeAnswer
    #
    # The answer set that's currently being inspected. This would point to an
    # object found in the answer set, see QuestionStatistics#answerSets.
    #
    # When the answer set selection changes, all the stats will be adjusted to
    # reflect the new ratios/metrics that are exclusive to that answer set.
    activeAnswer: (->
      @get('answerSets').findBy('active', true)
    ).property('answerSets')  # we could bind to `answerSets.@each.active` but
                              # that would trigger changes unnecessarily, so we
                              # opt for manual notification in the action

    # Tell our ratio calculator to use the newly-activated answer set's
    # "answer_matches" as the pool of answers to calculate ratio from
    updateCalculatorAnswerPool: (->
      @set('ratioCalculator.answerPool', @get('activeAnswer.answers'))
    ).observes('activeAnswer')

    correctResponseRatioLabel: (->
      I18n.t('correct_multiple_response_ratio',
        '%{ratio}% of your students responded correctly.',
        {
          ratio: Math.round(@get('correctResponseRatio') * 100)
        })
    ).property('correctResponseRatio')

    actions:
      activateAnswer: (blankId) ->
        @get('answerSets').forEach (answerSet) ->
          answerSet.set('active', answerSet.get('id') == blankId)

        # see comment on #activeAnswer
        @notifyPropertyChange('activeAnswer')