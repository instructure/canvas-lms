define [
  'ember'
  'underscore'
  'i18n!quiz_statistics'
], (Ember, _, I18n) ->
  Ember.ObjectController.extend
    needs: [ 'quizStatistics' ]

    participantCount: Ember.computed.alias('ratioCalculator.participantCount'),
    correctResponseRatio: Ember.computed.alias('ratioCalculator.ratio')

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
          ratio: Math.round(@get('correctResponseRatio') * 100)
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
        @set('detailsVisible', !@get('detailsVisible'))