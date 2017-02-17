define [
  'underscore'
  'Backbone'
  'compiled/collections/OutcomeResultCollection'
  'd3'
  'jst/outcomes/accessibleLineGraph'
  'compiled/underscore-ext/sum'
], (_, Backbone, OutcomeResultCollection, d3, accessibleTemplate) ->
  # Trend class based on formulae found here:
  # http://classroom.synonym.com/calculate-trendline-2709.html
  class Trend
    constructor: (@rawData) ->

    # Returns: [[x1, y1], [x2, y2]]
    data: ->
      [[
        @xValue(@rawData[0])
        @yIntercept()
        @xValue(_.last(@rawData))
        (@slope() * @xValue(_.last(@rawData))) + @yIntercept()
      ]]

    slope: ->
      (@a() - @b()) / (@c() - @d())

    yIntercept: ->
      (@e() - @f()) / @n()

    # The number of points of data.
    n: ->
      @rawData.length

    # `n` times the sum of the products of each x & y pair.
    a: ->
      @n() * _.sum(@rawData, (point) => (@xValue(point) * @yValue(point)))

    # The product of the sum of all x values and all y values.
    b: ->
      _.sum(@rawData, @xValue) * _.sum(@rawData, @yValue)

    # `n` times the sum of all x values individually squared.
    c: ->
      @n() * _.sum(@rawData, (point) => Math.pow(@xValue(point), 2))

    # The sum of all x values squared.
    d: ->
      Math.pow(_.sum(@rawData, @xValue), 2)

    # The sum of all y values.
    e: ->
      _.sum(@rawData, @yValue)

    # The slope times the sum of all x values.
    f: ->
      @slope() * _.sum(@rawData, @xValue)

    xValue: (point) ->
      point.x

    yValue: (point) ->
      point.y

  class OutcomeLineGraphView extends Backbone.View
    @optionProperty 'el'
    @optionProperty 'height'
    @optionProperty 'limit'
    @optionProperty 'margin'
    @optionProperty 'model'
    @optionProperty 'timeFormat'
    defaults:
      height: 200
      limit: 8
      margin: {top: 20, right: 20, bottom: 30, left: 40}
      # 2015-02-06T17:49:08Z
      timeFormat: "%Y-%m-%dT%XZ"

    initialize: ->
      super
      @deferred = $.Deferred()
      @collection = new OutcomeResultCollection([], {
        outcome: @model
      })
      @collection.on 'fetched:last', =>
        @deferred.resolve()
      @collection.fetch()

    render: ->
      if @deferred.isResolved()
        return @ if @collection.isEmpty()

        @_prepareScales()
        @_prepareAxes()
        @_prepareLines()

        @svg = d3.select(@el)
          .append("svg")
            .attr("width", @width() + @margin.left + @margin.right)
            .attr("height", @height + @margin.top + @margin.bottom)
            .attr("aria-hidden", true)
          .append("g")
            .attr("transform", "translate(#{@margin.left}, #{@margin.top})")

        @_appendAxes()
        @_appendLines()

        @$('.screenreader-only').append(accessibleTemplate(@toJSON()))
      else
        @deferred.done(@render)


      @

    toJSON: ->
      current_user_name: ENV.current_user.display_name
      data: @data()
      outcome_name: @model.get('friendly_name')

    # Data helpers
    data: ->
      @_data ?= @collection.chain()
        .last(@limit)
        .map((outcomeResult, i) =>
          x: i
          y: @percentageFor(outcomeResult.get('score'))
          date: outcomeResult.get('submitted_or_assessed_at')
        ).value()

    masteryPercentage: ->
      (@model.get('mastery_points') / @model.get('points_possible')) * 100

    percentageFor: (score) ->
      ((score / @model.get('points_possible')) * 100)

    xValue: (point) =>
      @x(point.x)

    yValue: (point) =>
      @y(point.y)

    # View helpers
    _appendAxes: ->
      @svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0,#{@height})")
        .call(@xAxis)

      @svg.append("g")
        .attr("class", "date-guides")
        .attr("transform", "translate(0,#{@height})")
        .call(@dateGuides)

      @svg.append("g")
        .attr("class", "y axis")
        .call(@yAxis)

      @svg.append("g")
        .attr("class", "guides")
        .call(@yGuides)

      @svg.append("g")
        .attr("class", "mastery-percentage-guide")
        .style("stroke-dasharray", ("3, 3"))
        .call(@masteryPercentageGuide)

    _appendLines: ->
      @svg.selectAll("circle")
        .data(@data())
        .enter().append("circle")
        .attr("fill", "black")
        .attr("r", 3)
        .attr("cx", @xValue)
        .attr("cy", @yValue)

      @svg.append("path")
        .datum(@data())
        .attr("d", @line)
        .attr("class", "line")
        .attr("stroke", "black")
        .attr("stroke-width", 1)
        .attr("fill", "none")

      if @trend?
        @svg.selectAll(".trendline")
          .data(@trend.data())
          .enter()
          .append("line")
          .attr("class", "trendline")
          .attr("x1", (d) => @x(d[0]))
          .attr("y1", (d) => @y(d[1]))
          .attr("x2", (d) => @x(d[2]))
          .attr("y2", (d) => @y(d[3]))
          .attr("stroke-width", 1)

      @svg


    _prepareAxes: ->
      @xAxis = d3.svg.axis()
        .scale(@x)
        .tickFormat('')
      @dateGuides = d3.svg.axis()
        .scale(@xTimeScale)
        .tickValues([
          _.first(@data()).date
          _.last(@data()).date
        ])
        .tickFormat((d) -> d3.time.format("%m/%d")(d))
      @yAxis = d3.svg.axis()
        .scale(@y)
        .orient("left")
        .tickFormat((d) -> "#{d}%" )
        .tickValues([0, 50, 100])
      @yGuides = d3.svg.axis()
        .scale(@y)
        .orient("left")
        .tickValues([50, 100])
        .tickSize(-@width(), 0, 0)
        .tickFormat("")
      @masteryPercentageGuide = d3.svg.axis()
        .scale(@y)
        .orient("left")
        .tickValues([@masteryPercentage()])
        .tickSize(-@width(), 0, 0)
        .tickFormat("")

    _prepareLines: ->
      if @data().length >=3
        @trend = new Trend(@data())

      @line = d3.svg.line()
        .x(@xValue)
        .y(@yValue)
        .interpolate('linear')

    _prepareScales: ->
      @x = d3.scale.linear()
        .range([0, @width()])
        .domain([0, @limit - 1])
      @xTimeScale = d3.time.scale()
        .range([0, @xTimeScaleWidth()])
        .domain([
          _.first(@data()).date
          _.last(@data()).date
        ])
      @y = d3.scale.linear()
        .range([@height, @margin.bottom])
        .domain([0, 100])

    width: ->
      @$el.width() - @margin.left - @margin.right - 10

    # The width of the axis used to display the first and last date of scores
    # displayed has to be different than the full width, in case the number
    # of points is fewer than the limit (8). What we want is the width of the
    # element reduced by the difference between the limit and the number of
    # points we actually have, multiplied by the width each point represents,
    # based on the element's width and the limit.
    xTimeScaleWidth: ->
      (@width() - (
        (@width() / (@limit - 1)) *
        (@limit - @data().length)
      ))

