define [
  'ember'
  '../multiple_choice/answer_bars_view'
], (Ember, BaseChartView) ->
  # This view adds the ability to update the regular Multiple-Choice bar chart
  # when the answer selection changes.
  BaseChartView.extend
    templateName: 'quiz/statistics/questions/multiple_choice/answer_bars'

    updateChart: (->
      Ember.run.schedule 'actions', this, ->
        @rerender()
        @removeInspector()
    ).observes('controller.chartData')
