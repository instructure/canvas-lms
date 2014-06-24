define [
  'ember'
  'vendor/d3.v3'
], ({View}, d3) ->
  View.extend
    width: 270
    height: 14 * 3
    renderChart: (->
      barHeight = @get('height') / 3
      barWidth = @get('width') / 2

      data = @get('controller.chartData')

      svg = @svg = d3.select(@$('svg')[0])
        .attr('width', @get('width'))
        .attr('height', @get('height'))
        .append('g')

      svg.selectAll('.bar.correct')
        .data(data.ratio)
        .enter()
          .append('rect')
            .attr('class', 'bar correct')
            .attr('x', barWidth)
            .attr('width', (correctRatio) -> correctRatio * barWidth)
            .attr('y', (d, bracket) -> bracket * barHeight)
            .attr('height', () -> barHeight-1)

      svg.selectAll('.bar.incorrect')
        .data(data.ratio)
        .enter()
          .append('rect')
            .attr('class', 'bar incorrect')
            .attr('x', (correctRatio) -> -1 * (1 - correctRatio * barWidth))
            .attr('width', (correctRatio) -> (1 - correctRatio) * barWidth)
            .attr('y', (d, bracket) -> bracket*barHeight)
            .attr('height', () -> barHeight-1)
    ).on('didInsertElement')

    removeChart: (->
      @svg.remove()
    ).on('willDestroyElement')
