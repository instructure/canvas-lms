define [
  'ember'
  'vendor/d3.v3'
  '../../../../../mixins/views/chart_inspector'
], ({View}, d3, ChartInspectorMixin) ->
  # This view draws an area chart with a trend line plotting the graded scores
  # for essay responses.
  View.extend ChartInspectorMixin,
    tooltipOptions:
      position:
        my: 'center+8 bottom'
        at: 'center top-12'

    renderChart: (->
      data = @get('controller.chartData')

      # radius of the circles for each distinct score
      radius = 4

      # need to apply some margins to ensure the circles are visible on edges
      circleVisibilityThreshold = radius * 4
      margin = {
        # so the lowest score circle is visible
        left: circleVisibilityThreshold
        # so the highest score circle is visible from both the top and right
        top: circleVisibilityThreshold
        right: circleVisibilityThreshold
        bottom: 0
      }

      width = 580 - margin.left - margin.right
      height = 120 - margin.top - margin.bottom

      x = d3.scale.linear().range([0, width])
      y = d3.scale.linear().range([height, 0])

      svg = @svg = d3.select(@$('svg')[0])
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
          .attr('transform', "translate(#{margin.left},#{margin.top})")

      x.domain(d3.extent(data, (d) -> d.score))
      y.domain([0, d3.max(data, (d) -> d.count)])

      line = d3.svg.line()
        .x((d) -> x(d.score))
        .y((d) -> y(d.count))

      area = d3.svg.area()
        .x((d) -> x(d.score))
        .y0(height)
        .y1((d) -> y(d.count))

      svg.selectAll('path.score-line')
        .data(data)
        .enter()
          .append('path')
          .attr('class', 'score-line')
          .attr('d', line(data))

      svg.append('path')
        .datum(data)
        .attr('class', 'area')
        .attr('d', area)

      svg.selectAll('circle')
        .data(data)
        .enter()
          .append('circle')
          .attr('cx', (d) -> x(d.score))
          .attr('cy', (d) -> y(d.count) - radius)
          .attr('r', radius*2)
          .inspectable(this)
    ).on('didInsertElement')

    removeChart: (->
      @svg.remove()
    ).on('willDestroyElement')