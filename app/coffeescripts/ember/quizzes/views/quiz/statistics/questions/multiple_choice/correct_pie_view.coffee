define [ 'ember', 'vendor/d3.v3' ], (Ember, d3) ->
  # This view plots a donut chart that shows the ratio of correct answers.
  Ember.View.extend
    # @config [Integer] [radius=80]
    #   Radius of the donut chart in pixels.
    radius: 80

    CIRCLE: 2 * Math.PI
    FMT_PERCENT: d3.format('%')

    renderChart: (->
      ratio = @get('controller.correctResponseRatio')

      @arc = d3.svg.arc()
        .innerRadius(@radius / 2)
        .outerRadius(@radius / 2.5)
        .startAngle(0)

      @svg = d3.select(@$('svg')[0])
        .attr('width', @radius)
        .attr('height', @radius)
        .append('g')
          .attr('transform', "translate(#{@radius/2},#{@radius/2})")

      background = @svg.append('path')
        .datum({ endAngle: @CIRCLE })
        .attr('class', 'background')
        .attr('d', @arc)

      @foreground = @svg.append('path')
        .datum({ endAngle: @CIRCLE * ratio })
        .attr('class', 'foreground')
        .attr('d', @arc)

      @text = @svg.append('text')
        .attr('text-anchor', 'middle')
        .attr('dy', '.35em')
        .text(@FMT_PERCENT(ratio))
    ).on('didInsertElement')

    removeChart: (->
      @svg.remove()
    ).on('willDestroyElement')