define [
  'ember'
  'vendor/d3.v3'
], ({View}, d3) ->
  View.extend
    renderChart: (->
      barHeight = 14
      chunkSize = 35
      w = 270
      h = 80
      midPoint = w/2

      data = @get('controller.chartData')

      x = d3.scale.linear().range([ 0, midPoint ])
      x.domain([ data.maxPoint, 0])

      svg = @svg = d3.select(@$('svg')[0])
        .attr('width', w)
        .attr('height', h)
        .append('g')

      svg.selectAll('.bar.correct')
        .data(data.correct)
        .enter()
          .append('rect')
            .attr('class', 'bar correct')
            .attr('x', (d, i)  -> midPoint)
            .attr('width', (d) -> midPoint - x(d))
            .attr('y', (d, i)  -> i*barHeight)
            .attr('height', (d) -> barHeight-1)

      svg.selectAll('.bar.incorrect')
        .data(data.incorrect)
        .enter()
          .append('rect')
            .attr('class', 'bar incorrect')
            .attr('x', x)
            .attr('width', (d) -> midPoint - x(d))
            .attr('y', (d, i) -> i*barHeight)
            .attr('height', (d) -> barHeight-1)
    ).on('didInsertElement')

    removeChart: (->
      @svg.remove()
    ).on('willDestroyElement')
