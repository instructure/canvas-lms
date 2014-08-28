define [ 'ember', 'i18n!quiz_statistics' ], (Ember, I18n) ->
  {alias} = Ember.computed

  Ember.ObjectController.extend
    needs: [ 'quizStatistics' ]

    participantCount: alias('ratioCalculator.participantCount').readOnly()
    correctResponseRatio: alias('ratioCalculator.ratio').readOnly()

    attemptsLabel: (->
      I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
        count: @get('responses'),
        total: @get('participantCount')
      })
    ).property('responses', 'participantCount')

    correctResponseRatioLabel: (->
      I18n.t('correct_response_ratio',
        '%{ratio}% of your students correctly answered this question.',
        {
          ratio: Ember.Util.round(@get('correctResponseRatio') * 100, 0)
        })
    ).property('correctResponseRatio')

    # When the question-details are expanded from the master level (as in, using
    # the Expand-All button), it overrides any collapsed state previously set
    # for each specific question (so it really does expand and collapse ALL.)
    inheritDetailVisibility: (->
      @set 'detailsVisible', @get('controllers.quizStatistics.allDetailsVisible')
    ).observes('controllers.quizStatistics.allDetailsVisible')

    actions:
      showDetails: ->
        @toggleProperty('detailsVisible')
        null