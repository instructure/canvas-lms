define [ 'ember', 'i18n!quiz_statistics' ], (Em, I18n) ->
  Em.ObjectController.extend
    chartData: (->
      participantCount = @get('participantCount')

      return Em.A() if participantCount == 0

      Em.A(@get('pointDistribution')).map (point) ->
        {
          id: "#{point.score}"
          score: point.score
          count: point.count
        }
    ).property('pointDistribution', 'participantCount')

    inspectorData: (->
      participantCount = @get('participantCount')

      @get('chartData').map (point) ->
        {
          id: point.id
          ratio: Em.Util.round(point.count / participantCount * 100, 0)
          responses: point.count
          text: I18n.t('essay_score', 'Score: %{score}', { score: point.score })
        }
    ).property('chartData')