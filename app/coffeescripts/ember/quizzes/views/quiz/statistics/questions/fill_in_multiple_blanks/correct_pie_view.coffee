define [
  'ember'
  '../multiple_choice/correct_pie_view'
], ({run}, BaseChartView) ->
  # This view adds the ability to update the regular Multiple-Choice pie chart
  # when the ratio changes.
  BaseChartView.extend
    templateName: 'quiz/statistics/questions/multiple_choice/correct_pie'

    updateChart: (->
      ratio = @get('controller.correctResponseRatio')

      return if ratio == undefined

      run.schedule 'render', this, ->
        @foreground.datum({ endAngle: ratio * @CIRCLE }).attr('d', @arc)
        @text.text(@FMT_PERCENT(ratio))
    ).observes('controller.correctResponseRatio')