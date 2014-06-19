define [ 'ember', 'vendor/d3.v3' ], (Ember, d3) ->
  Ember.View.extend
    chartOptions:
      marginTop: 0
      marginRight: 0
      marginBottom: 40
      marginLeft: -40
      w: 960
      h: 220
      barWidth: 10
      barMargin: 0.25

    generateScoreChart: (->
      data = @get('controller.scoreChartData')
      sz = data.length
      highest = d3.max(data)
      {marginTop, marginRight, marginBottom, marginLeft} = @chartOptions
      width = @chartOptions.w - marginLeft - marginRight
      height = @chartOptions.h - marginTop - marginBottom

      x = d3.scale.ordinal()
        .rangeRoundBands([0, @chartOptions.barWidth*sz], @chartOptions.barMargin)

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
        .attr('width', width + marginLeft + marginRight)
        .attr('height', height + marginTop + marginBottom)
        .append('g')
          .attr("transform", "translate(#{marginLeft},#{marginTop})");

      svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{height})")
        .call(xAxis)

      @_renderPercentileChart(svg, data, x, y, height)
      @_renderMedianDistGraph(svg, data, x, y)

      @svg = svg # so we can cleanup
    ).on('didInsertElement')

    _renderPercentileChart: (svg, percentileData, x, y, h) ->
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
            .attr('height', (d) -> h - y(d + visibilityThreshold));

    _renderMedianDistGraph: (svg, percentileData, x, y) ->
      data = d3.range(0, 101, 10).map (percentile) ->
        entries = percentileData.slice(percentile, percentile+10)
        point = d3.max(entries)

        { y: point, percentile: percentile + entries.indexOf(point) }

      # make it so that the line starts and ends on any bar's center, looks better
      paddingToCenter = x.rangeBand() / 2 - @get('chartOptions.barMargin')

      line = d3.svg.line()
        .x((d, i) -> x(d.percentile) + paddingToCenter)
        .y((d) -> y(d.y))
        .interpolate('basis')

      svg.selectAll('path.median-dist-graph')
        .data(data)
        .enter()
          .append('path')
          .attr('class', 'median-dist-graph')
          .attr('d', line(data))

    removeScoreChart: (->
      @svg.remove() if @svg
    ).on('willDestroyElement')
