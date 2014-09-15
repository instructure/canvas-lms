define [ 'ember', 'vendor/d3.v3' ], (Ember, d3) ->
  MARGIN_T = 0
  MARGIN_R = 0
  MARGIN_B = 40
  MARGIN_L = -40
  WIDTH = 960
  HEIGHT = 220
  BAR_WIDTH = 10
  BAR_MARGIN = 0.25

  SummaryView = Ember.View.extend
    generateScoreChart: (->
      data = @get('controller.scoreChartData')

      width  = WIDTH  - MARGIN_L - MARGIN_R
      height = HEIGHT - MARGIN_T - MARGIN_B

      highest = d3.max(data)

      x = d3.scale.ordinal()
        .rangeRoundBands([0, BAR_WIDTH * data.length ], BAR_MARGIN)

      y = d3.scale.linear()
        .range([ 0, highest ])
        .rangeRound([ height, 0 ])

      x.domain data.map (d, i) -> i
      y.domain [ 0, highest ]

      xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")
        .tickValues(d3.range(0, 101, 10))
        .tickFormat((d) -> d+'%')

      svg = d3.select(@$('svg')[0])
        .attr('width', width + MARGIN_L + MARGIN_R)
        .attr('height', height + MARGIN_T + MARGIN_B)
        .attr('viewBox', "0 0 #{width + MARGIN_L + MARGIN_R} #{height + MARGIN_T + MARGIN_B}")
        .attr('preserveAspectRatio', 'xMinYMax')
        .append('g')
          .attr("transform", "translate(#{MARGIN_L},#{MARGIN_T})")

      svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{height})")
        .call(xAxis)

      renderPercentileChart(svg, data, x, y, height)
      renderMedianDistGraph(svg, data, x, y, BAR_MARGIN)

      @svg = svg # so we can cleanup
    ).on('didInsertElement')

    removeScoreChart: (->
      @svg.remove() if @svg
    ).on('willDestroyElement')

  renderPercentileChart = (svg, percentileData, x, y, height) ->
    data = percentileData
    highest = y.domain()[1]
    # we want percentiles with a value of 0 to still show up but really small
    # as to not be confused with actual data
    visibilityThreshold = Math.min( highest / 100, 0.5 )

    svg.selectAll('rect.bar')
      .data(data)
      .enter()
        .append('rect')
          .attr("class", 'bar')
          .attr('x', (d, i) -> x(i))
          .attr('width', x.rangeBand)
          .attr('y', (d) -> y(d + visibilityThreshold))
          .attr('height', (d) -> height - y(d + visibilityThreshold))

  renderMedianDistGraph = (svg, percentileData, x, y, barMargin) ->
    data = d3.range(0, 101, 10).map (percentile) ->
      entries = percentileData.slice(percentile, percentile+10)
      point = d3.max(entries)

      { y: point, percentile: percentile + entries.indexOf(point) }

    # -- disable line until we figure out proper normal distribution --
    #
    # make it so that the line starts and ends on any bar's center, looks better
    # paddingToCenter = x.rangeBand() / 2 - barMargin
    # line = d3.svg.line()
    #   .x((d, i) -> x(d.percentile) + paddingToCenter)
    #   .y((d) -> y(d.y))
    #   .interpolate('basis')

    svg.selectAll('path.median-dist-graph')
      .data(data)
      .enter()
        .append('path')
        .attr('class', 'median-dist-graph')
        # .attr('d', line(data))

  SummaryView
