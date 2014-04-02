define [
  'ember'
  'vendor/d3.v3'
], ({View}, d3) ->
  # This view plots a donut chart that shows the ratio of correct answers.
  View.extend
    # @config [Integer] [radius=80]
    #   Radius of the donut chart in pixels.
    radius: 80
    formatPercent: d3.format('%')

    renderChart: (->
      ratio = @get('controller.correctStudentRatio')
      circle = 2 * Math.PI

      arc = d3.svg.arc()
        .innerRadius(@radius / 2)
        .outerRadius(@radius / 2.5)
        .startAngle(0)

      svg = @svg = d3.select(@$('svg')[0])
        .attr('width', @radius)
        .attr('height', @radius)
        .append('g')
          .attr('transform', "translate(#{@radius/2},#{@radius/2})")

      background = svg.append('path')
        .datum({ endAngle: circle })
        .attr('class', 'background')
        .attr('d', arc)

      foreground = svg.append('path')
        .datum({ endAngle: circle * ratio })
        .attr('class', 'foreground')
        .attr('d', arc)

      text = svg.append('text')
        .attr('text-anchor', 'middle')
        .attr('dy', '.35em')
        .text(@formatPercent(ratio))
    ).on('didInsertElement')

    removeChart: (->
      @svg.remove()
    ).on('willDestroyElement')