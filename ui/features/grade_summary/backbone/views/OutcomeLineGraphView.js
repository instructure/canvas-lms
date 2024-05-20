//
// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import $ from 'jquery'
import {sumBy} from 'lodash'
import Backbone from '@canvas/backbone'
import I18n from '@canvas/i18n'
import OutcomeResultCollection from '../collections/OutcomeResultCollection'
import d3 from 'd3'
import accessibleTemplate from '../../jst/accessibleLineGraph.handlebars'

const dateTimeFormatter = Intl.DateTimeFormat(I18n.currentLocale(), {
  day: 'numeric',
  month: 'numeric',
})

const first = array => array.at(0)
const last = array => array.at(-1)

// Trend class based on formulae found here:
// http://classroom.synonym.com/calculate-trendline-2709.html
class Trend {
  constructor(rawData) {
    this.rawData = rawData
  }

  // Returns: [[x1, y1], [x2, y2]]
  data() {
    return [
      [
        this.rawData[0].x,
        this.yIntercept(),
        last(this.rawData).x,
        this.slope() * last(this.rawData).x + this.yIntercept(),
      ],
    ]
  }

  slope() {
    return (this.a() - this.b()) / (this.c() - this.d())
  }

  yIntercept() {
    return (this.e() - this.f()) / this.n()
  }

  // The number of points of data.
  n() {
    return this.rawData.length
  }

  // `n` times the sum of the products of each x & y pair.
  a() {
    return this.n() * sumBy(this.rawData, p => p.x * p.y)
  }

  // The product of the sum of all x values and all y values.
  b() {
    return sumBy(this.rawData, p => p.x) * sumBy(this.rawData, p => p.y)
  }

  // `n` times the sum of all x values individually squared.
  c() {
    return this.n() * sumBy(this.rawData, p => p.x * p.x)
  }

  // The sum of all x values squared.
  d() {
    return Math.pow(
      sumBy(this.rawData, p => p.x),
      2
    )
  }

  // The sum of all y values.
  e() {
    return sumBy(this.rawData, p => p.y)
  }

  // The slope times the sum of all x values.
  f() {
    return this.slope() * sumBy(this.rawData, p => p.x)
  }
}

class OutcomeLineGraphView extends Backbone.View {
  constructor(...args) {
    super(...args)
    this.xValue = this.xValue.bind(this)
    this.yValue = this.yValue.bind(this)
  }

  initialize() {
    super.initialize(...arguments)
    this.deferred = $.Deferred()
    this.collection = new OutcomeResultCollection([], {
      outcome: this.model,
    })
    this.collection.on('fetched:last', () => {
      return this.deferred.resolve()
    })
    return this.collection.fetch()
  }

  render() {
    if (this.deferred.state() === 'resolved') {
      if (this.collection.isEmpty()) {
        return this
      }

      this._prepareScales()
      this._prepareAxes()
      this._prepareLines()

      this.svg = d3
        .select(this.el)
        .append('svg')
        .attr('width', this.width() + this.margin.left + this.margin.right)
        .attr('height', this.height + this.margin.top + this.margin.bottom)
        .attr('aria-hidden', true)
        .append('g')
        .attr('transform', `translate(${this.margin.left}, ${this.margin.top})`)

      this._appendAxes()
      this._appendLines()

      this.$('.screenreader-only').append(accessibleTemplate(this.toJSON()))
    } else {
      this.deferred.done(this.render)
    }

    return this
  }

  toJSON() {
    return {
      current_user_name: ENV.current_user.display_name,
      data: this.data(),
      outcome_name: this.model.get('friendly_name'),
    }
  }

  // Data helpers
  data() {
    if (this._data === null || typeof this._data === 'undefined') {
      this._data = this.collection
        .chain()
        .last(this.limit)
        .map((outcomeResult, i) => ({
          x: i,
          y: this.percentageFor(outcomeResult.get('score')),
          date: outcomeResult.get('submitted_or_assessed_at'),
        }))
        .value()
    }
    return this._data
  }

  masteryPercentage() {
    if (this.model.get('points_possible') > 0) {
      return (this.model.get('mastery_points') / this.model.get('points_possible')) * 100
    } else {
      return 100
    }
  }

  percentageFor(score) {
    if (this.model.get('points_possible') > 0) {
      return (score / this.model.get('points_possible')) * 100
    } else {
      return (score / this.model.get('mastery_points')) * 100
    }
  }

  xValue(point) {
    return this.x(point.x)
  }

  yValue(point) {
    return this.y(point.y)
  }

  // View helpers
  _appendAxes() {
    this.svg
      .append('g')
      .attr('class', 'x axis')
      .attr('transform', `translate(0,${this.height})`)
      .call(this.xAxis)

    this.svg
      .append('g')
      .attr('class', 'date-guides')
      .attr('transform', `translate(0,${this.height})`)
      .call(this.dateGuides)

    this.svg.append('g').attr('class', 'y axis').call(this.yAxis)

    this.svg.append('g').attr('class', 'guides').call(this.yGuides)

    return this.svg
      .append('g')
      .attr('class', 'mastery-percentage-guide')
      .style('stroke-dasharray', '3, 3')
      .call(this.masteryPercentageGuide)
  }

  _appendLines() {
    this.svg
      .selectAll('circle')
      .data(this.data())
      .enter()
      .append('circle')
      .attr('fill', 'black')
      .attr('r', 3)
      .attr('cx', this.xValue)
      .attr('cy', this.yValue)

    this.svg
      .append('path')
      .datum(this.data())
      .attr('d', this.line)
      .attr('class', 'line')
      .attr('stroke', 'black')
      .attr('stroke-width', 1)
      .attr('fill', 'none')

    if (this.trend != null) {
      this.svg
        .selectAll('.trendline')
        .data(this.trend.data())
        .enter()
        .append('line')
        .attr('class', 'trendline')
        .attr('x1', d => this.x(d[0]))
        .attr('y1', d => this.y(d[1]))
        .attr('x2', d => this.x(d[2]))
        .attr('y2', d => this.y(d[3]))
        .attr('stroke-width', 1)
    }

    return this.svg
  }

  _prepareAxes() {
    this.xAxis = d3.svg.axis().scale(this.x).tickFormat('')
    this.dateGuides = d3.svg
      .axis()
      .scale(this.xTimeScale)
      .tickValues([first(this.data()).date, last(this.data()).date])
      .tickFormat(d => dateTimeFormatter.format(d))
    this.yAxis = d3.svg
      .axis()
      .scale(this.y)
      .orient('left')
      .tickFormat(d => I18n.n(d, {percentage: true}))
      .tickValues([0, 50, 100])
    this.yGuides = d3.svg
      .axis()
      .scale(this.y)
      .orient('left')
      .tickValues([50, 100])
      .tickSize(-this.width(), 0, 0)
      .tickFormat('')
    return (this.masteryPercentageGuide = d3.svg
      .axis()
      .scale(this.y)
      .orient('left')
      .tickValues([this.masteryPercentage()])
      .tickSize(-this.width(), 0, 0)
      .tickFormat(''))
  }

  _prepareLines() {
    if (this.data().length >= 3) {
      this.trend = new Trend(this.data())
    }

    return (this.line = d3.svg.line().x(this.xValue).y(this.yValue).interpolate('linear'))
  }

  _prepareScales() {
    this.x = d3.scale
      .linear()
      .range([0, this.width()])
      .domain([0, this.limit - 1])
    this.xTimeScale = d3.time
      .scale()
      .range([0, this.xTimeScaleWidth()])
      .domain([first(this.data()).date, last(this.data()).date])
    return (this.y = d3.scale.linear().range([this.height, this.margin.bottom]).domain([0, 100]))
  }

  width() {
    return this.$el.width() - this.margin.left - this.margin.right - 10
  }

  // The width of the axis used to display the first and last date of scores
  // displayed has to be different than the full width, in case the number
  // of points is fewer than the limit (8). What we want is the width of the
  // element reduced by the difference between the limit and the number of
  // points we actually have, multiplied by the width each point represents,
  // based on the element's width and the limit.
  xTimeScaleWidth() {
    return this.width() - (this.width() / (this.limit - 1)) * (this.limit - this.data().length)
  }
}

OutcomeLineGraphView.optionProperty('el')
OutcomeLineGraphView.optionProperty('height')
OutcomeLineGraphView.optionProperty('limit')
OutcomeLineGraphView.optionProperty('margin')
OutcomeLineGraphView.optionProperty('model')
OutcomeLineGraphView.optionProperty('timeFormat')
OutcomeLineGraphView.prototype.defaults = {
  height: 200,
  limit: 8,
  margin: {top: 20, right: 20, bottom: 30, left: 40},
  // 2015-02-06T17:49:08Z
  timeFormat: '%Y-%m-%dT%XZ',
}

export default OutcomeLineGraphView
