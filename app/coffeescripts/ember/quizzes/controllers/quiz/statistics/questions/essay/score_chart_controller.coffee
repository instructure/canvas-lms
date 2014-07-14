define [
  'ember'
  'i18n!quiz_statistics'
], (Ember, I18n) ->
  {A} = Ember

  Ember.ObjectController.extend
    chartData: (->
      participantCount = @get('participantCount')

      return A() if participantCount == 0

      A(@get('pointDistribution')).map (point) ->
        {
          id: "#{point.score}"
          score: point.score
          count: point.count
        }
    ).property('pointDistribution', 'participantCount')

    inspectorData: (->
      participantCount = @get('participantCount')

      @get('chartData').map (point) ->
        ratio = if participantCount > 0
          Ember.Util.round(point.count / participantCount * 100, 0)
        else
          0

        {
          id: point.id
          ratio: ratio
          responses: point.count
          text: I18n.t('essay_score', 'Score: %{score}', { score: point.score })
        }
    ).property('chartData')
