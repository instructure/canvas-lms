define [
  'underscore'
  'Backbone'
  'compiled/util/Popover'
  'compiled/models/grade_summary/Outcome'
  'd3'
  'jst/outcomes/outcomePopover'
], (_, {View}, Popover, Outcome, d3, popover_template) ->

  class OutcomeColumnView extends View

    popover_template: popover_template

    @optionProperty 'totalsFn'

    inside: false

    TIMEOUT_LENGTH: 50

    events:
      mouseenter: 'mouseenter'
      mouseleave: 'mouseleave'

    createPopover: (e) ->
      @totalsFn()
      @pickColors()
      attributes = new Outcome(@attributes)
      popover = new Popover(e, @popover_template(attributes.present()), verticalSide: 'bottom', invertOffset: true)
      popover.el.on('mouseenter', @mouseenter)
      popover.el.on('mouseleave', @mouseleave)
      @renderChart()
      popover.show(e)
      popover

    mouseenter: (e) =>
      @popover = @createPopover(e) unless @popover
      @inside  = true

    mouseleave: (e) =>
      @inside  = false
      setTimeout =>
        return if @inside || !@popover
        @popover.hide()
        delete @popover
      , @TIMEOUT_LENGTH

    pickColors: ->
      data = @attributes.ratings
      return unless data
      last = data.length - 1
      mastery = @attributes.mastery_points
      mastery_pos = data.indexOf(
        _.find(data,
          (x) -> x.points == mastery
        )
      )
      color = d3.scale.linear()
        .domain([0, mastery_pos, (mastery_pos + last)/ 2, last])
        .range(["#416929", "#8bab58", "#e0d670", "#dd5c5c"])
      _.each(data, (rating, i) -> rating.color = color(i))

    renderChart: ->
      @data = _.filter(@attributes.ratings, (rating) -> rating.percent)
      @r = 50

      @arc = d3.svg.arc()
        .outerRadius(@r)
      @arcs = @renderArcs()
      @renderArcFills()
      @renderLabels()
      @renderLabelLines()

    renderArcs: ->
      w = 160
      h = 150

      vis = d3.select(".outcome-details .chart-image")
        .append("svg:svg")
        .data([@data])
        .attr("width", w)
        .attr("height", h)
        .append("svg:g")
        .attr("transform", "translate(#{w/2}, #{h/2})")

      pie = d3.layout.pie()
        .value((d) -> d.percent )

      arcs = vis.selectAll("g.slice")
        .data(pie)
        .enter()
        .append("svg:g")
        .attr("class", "slice")

      arcs

    renderArcFills: ->
      initialRadius = 10
      k = d3.interpolate(initialRadius, @r)
      arc = @arc
      radiusTween = (a) ->
        (t) -> arc.outerRadius(k(t))(a)

      @arc.outerRadius(initialRadius)
      @arcs.append("svg:path")
        .attr("fill", (d, i) => @data[i].color )
        .attr("d", @arc)
        .transition().duration(400).attrTween("d", radiusTween)
      @arc.outerRadius(@r)

    renderLabels: ->
      @arcs.append("svg:text")
        .attr("fill", "#4F5F6E")
        .attr("transform", (d) =>
          c = @getCentroid(d)
          c = _.map(c, (x) -> x * 2.3)
          "translate(#{c})"
        )
        .attr("text-anchor", (d) =>
          {angle, distanceToPi} = @getAngleInfo(d)
          return "middle" if distanceToPi < Math.PI/6
          if angle > Math.PI then "end" else "start"
        )
        .attr("dominant-baseline", (d) =>
          {angle, distanceToPi} = @getAngleInfo(d, sideways = true)
          return "middle" if distanceToPi < Math.PI/6
          if angle > Math.PI then "hanging" else "auto"
        )
        .text((d, i) => @data[i].percent+'%' )

    getAngleInfo: (d, sideways) ->
      angle = (d.endAngle + d.startAngle) / 2
      angle = (angle + Math.PI/2) % (2 * Math.PI) if sideways
      distanceToPi = Math.abs((angle + Math.PI/2) % Math.PI - Math.PI/2)
      {angle, distanceToPi}

    renderLabelLines: ->
      @arcs.append("svg:path")
        .attr("stroke", "#000")
        .attr("d", (d) =>
          c = @getCentroid(d)
          c1 = _.map(c, (x) -> x * 1.4)
          c2 = _.map(c, (x) -> x * 2.2)
          "M#{c1[0]} #{c1[1]} L#{c2[0]} #{c2[1]}"
        )

    getCentroid: (d) ->
      d.innerRadius = 0
      d.outerRadius = @r
      @arc.centroid(d)
