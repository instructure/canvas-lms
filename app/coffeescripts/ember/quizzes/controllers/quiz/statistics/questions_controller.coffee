define [
  'ember'
  'underscore'
  'i18n!quiz_statistics'
], (Ember, _, I18n) ->
  Ember.ObjectController.extend
    needs: [ 'quizStatistics' ],

    totalResponses: Ember.computed.alias('controllers.quizStatistics.model.uniqueCount'),

    attemptsLabel: (->
      I18n.t('attempts', 'Attempts: %{responses} out of %{totalResponses}', {
        responses: @get('responses'),
        totalResponses: @get('totalResponses')
      })
    ).property('responses', 'totalResponses')

    actions:
      showDetails: ->
        @set('detailsVisible', !@get('detailsVisible'))

    # When the question-details are expanded from the master level (as in, using
    # the Expand-All button), it overrides any collapsed state previously set
    # for each specific question (so it really does expand and collapse ALL.)
    inheritDetailVisibility: (->
      @set 'detailsVisible', @get('controllers.quizStatistics.allDetailsVisible')
    ).observes('controllers.quizStatistics.allDetailsVisible')