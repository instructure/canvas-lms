define [
  'ember'
  'underscore'
  'vendor/d3.v3'
  'compiled/behaviors/tooltip'
], ({View}, _, d3) ->
  # This view renders a bar chart that plots each question answer versus the
  # amount of responses each answer has received.
  #
  # Also, each bar that represents an answer provides a tooltip on hover that
  # displays more information.
  View.extend
    # @config [Integer] [barWidth=30]
    #   Width of the bars in the chart in pixels.
    barWidth: 30
    # @config [Integer] [barMargin=1]
    #   Whitespace to offset the bars by, in pixels.
    barMargin: 1
    xOffset: 16
    yAxisLabel: ''
    xAxisLabels: false
    linearScale: true
    w: 220
    h: 120

    hideAuxiliaryContent: (->
      @$('.auxiliary').hide()
    ).on('didInsertElement')

    buildInspector: ->
      @inspector = @$('.inspector').tooltip({
        tooltipClass: 'center bottom vertical',
        show: false,
        hide: false
      }).data('tooltip')

    removeInspector: (->
      if @inspector
        @inspector.destroy()
        @inspector = null
    ).on('willDestroyElement')

    inspect: (datapoint, target) ->
      content = @$(".auxiliary [data-answer='#{datapoint.id}']")
      inspector = @inspector || @buildInspector()
      inspector.option
        content: () -> content.clone()
        position:
          my: "center+#{@get('barWidth') / 2} bottom"
          at: 'center top-8'
          of: target
          collision: 'fit fit'
      inspector.element.mouseover()

    stopInspecting: ->
      @inspector.element.mouseout()

    renderChart: (->
      data = @get('controller.chartData')
      $container = @$().parent()

      sz = _.reduce data, ((sum, item) -> sum + item.y), 0

      highest = Math.max.apply(Math, _.pluck(data, 'y'))

      margin = { top: 0, right: 0, bottom: 0, left: 0 }
      width = @get('w') - margin.left - margin.right
      height = @get('h') - margin.top - margin.bottom
      barWidth = @get('barWidth')
      barMargin = @get('barMargin')
      xOffset = @get('xOffset')
      visibilityThreshold = Math.min(1.0, highest / 100.0)

      x = d3.scale.ordinal()
        .rangeRoundBands([0, @get('barWidth') * sz], .025)

      y = d3.scale.linear()
        .range([height + visibilityThreshold, 0])

      svg = d3.select(@$('svg')[0])
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
        .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      x.domain _.map data, (d, i) ->
        d.label || i
      y.domain [ 0, sz ]

      svg.selectAll('.bar')
        .data(data)
        .enter().append('rect')
          .attr("class", (d) => @classifyChartBar(d))
          .attr("x", (d, i) -> i*(barWidth + barMargin) + xOffset)
          .attr("width", barWidth)
          .attr("y", (d) -> y(d.y + visibilityThreshold))
          .attr("height", (d) -> height - y(d.y + visibilityThreshold))
          .on('mouseover', (d) => @inspect(d, d3.event.target))
          .on('mouseout', => @stopInspecting())

      # If the special "No Answer" is present, we represent it as a diagonally-
      # striped bar, but to do that we need to render the <svg:pattern> that
      # generates the stripes and use that as a fill pattern, and we also need
      # to create the <svg:rect> that will be filled with that pattern.
      if noAnswer = _.where(data, { id: 'none' })[0]
        @renderStripePattern(svg)
        index = data.indexOf(noAnswer)
        svg.selectAll('.bar.bar-striped')
          .data([ noAnswer ])
          .enter().append('rect')
            .attr('class', 'bar bar-striped')
            # We need to inline the fill style because we are referencing an
            # inline pattern (#diagonalStripes) which is unreachable from a CSS
            # directive.
            #
            # See this link [StackOverflow] for more info: http://bit.ly/1uDTqyn
            .attr('style', 'fill: url(#diagonalStripes);')
            # remove 2 pixels from width and height, and offset it by {1,1} on
            # both axes to "contain" it inside the margins of the bg rect
            .attr('x', (d) -> index*(barWidth + barMargin) + xOffset + 1)
            .attr('width', barWidth-2)
            .attr('y', (d) -> y(d.y + visibilityThreshold) + 1)
            .attr('height', (d) -> height - y(d.y + visibilityThreshold) - 2)

      @svg = svg # for cleanup
    ).on('didInsertElement')

    removeChart: (->
      if @svg
        @svg.remove()
    ).on('willDestroyElement')

    renderStripePattern: (svg) ->
      svg.append('pattern')
        .attr('id', 'diagonalStripes')
        .attr('width', 5)
        .attr('height', 5)
        .attr('patternTransform', 'rotate(45 0 0)')
        .attr('patternUnits', 'userSpaceOnUse')
        .append('g')
          .append('path')
            .attr('d', 'M0,0 L0,10')

    classifyChartBar: (answer) ->
      if answer.correct
        'bar bar-highlighted'
      else
        'bar'
