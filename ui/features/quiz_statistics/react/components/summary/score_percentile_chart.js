/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import createChartComponent, {addTitle, addDescription} from '../../hocs/createChartComponent'
import d3 from 'd3'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

const I18n = useI18nScope('quiz_statistics.summary')

const max = d3.max
const sum = d3.sum

const MARGIN_T = 0
const MARGIN_R = 18
const MARGIN_B = 60
const MARGIN_L = 34

const ScorePercentileChart = createChartComponent({
  createChart(node, props) {
    const width = props.width - MARGIN_L - MARGIN_R
    const height = props.height - MARGIN_T - MARGIN_B

    // the x scale is static since it will always represent the 100
    // percentiles, so we can avoid recalculating it on every update:
    const x = d3.scale.ordinal().rangeRoundBands([0, width], props.barPadding, 0)
    x.domain(d3.range(0, 101, 1))

    this.y = d3.scale.linear().range([height, 0])

    const xAxis = d3.svg
      .axis()
      .scale(x)
      .orient('bottom')
      .tickValues(d3.range(0, 101, 10))
      .tickFormat(function (d) {
        return d + '%'
      })

    this.yAxis = d3.svg.axis().scale(this.y).orient('left').outerTickSize(0).ticks(props.numTicks)

    const svg = d3
      .select(node)
      .attr('role', 'document')
      .attr('aria-role', 'document')
      .attr('width', width + MARGIN_L + MARGIN_R)
      .attr('height', height + MARGIN_T + MARGIN_B)
      .attr(
        'viewBox',
        '0 0 ' + (width + MARGIN_L + MARGIN_R) + ' ' + (height + MARGIN_T + MARGIN_B)
      )
      .attr('preserveAspectRatio', 'xMidYMax')
      .append('g')

    this.title = addTitle(svg, '')

    const descriptionHolder = this.wrapperRef.current ? d3.select(this.wrapperRef.current) : svg
    this.description = addDescription(descriptionHolder, '')

    svg
      .append('g')
      .attr('class', 'x axis')
      .attr('aria-hidden', true)
      .attr('transform', 'translate(5,' + height + ')')
      .call(xAxis)

    this.yAxisContainer = svg
      .append('g')
      .attr('class', 'y axis')
      .attr('aria-hidden', true)
      .call(this.yAxis)

    const barContainer = svg.append('g')

    this.x = x
    this.height = height
    this.barContainer = barContainer

    this.updateChart(svg, props)

    return svg
  },

  updateChart(svg, props) {
    const data = (this.chartData = this.calculateChartData(props))
    const avgScore = (props.scoreAverage / props.pointsPossible) * 100.0
    const labelOptions = this.calculateStudentStatistics(avgScore, data)
    let textForScreenreaders = I18n.t(
      'audible_chart_description',
      '%{above_average} students scored above or at the average, and %{below_average} below. ',
      {
        above_average: labelOptions.aboveAverage,
        below_average: labelOptions.belowAverage,
      }
    )

    data.forEach(function (datum, i) {
      if (datum !== 0) {
        textForScreenreaders += I18n.t(
          {
            one: '1 student in percentile %{percentile}. ',
            other: '%{count} students in percentile %{percentile}. ',
          },
          {
            count: datum,
            percentile: i + '',
          }
        )
      }
    })

    this.title.text(I18n.t('chart_title', 'Score percentiles chart'))
    this.description.text(textForScreenreaders)

    this.renderBars(this.barContainer, props)
  },

  renderBars(svg, props) {
    const data = this.chartData

    const height = this.height
    const highest = max(data)

    const x = this.x
    const y = this.y

    y.range([0, highest]).rangeRound([height, 0]).domain([0, highest])

    const step = -Math.ceil((highest + 1) / props.numTicks)

    this.yAxis.tickValues(d3.range(highest, 0, step)).tickFormat(function (d) {
      return Math.floor(d)
    })

    this.yAxisContainer.call(this.yAxis).selectAll('text').attr('dy', '.8em')
    this.yAxisContainer.selectAll('line').attr('y1', '.5').attr('y2', '.5')

    const visibilityThreshold = Math.max(highest / 100, props.minBarHeight)

    const bars = svg.selectAll('rect.bar').data(data)

    bars
      .enter()
      .append('rect')
      .attr('class', 'bar')
      .attr('x', function (d, i) {
        return x(i)
      })
      .attr('y', height)
      .attr('width', x.rangeBand)
      .attr('height', 0)

    bars
      .transition()
      .delay(props.animeDelay)
      .duration(props.animeDuration)
      .attr('y', function (d) {
        return y(d) - visibilityThreshold
      })
      .attr('height', function (d) {
        return height - y(d) + visibilityThreshold
      })

    bars.exit().remove()
  },

  /**
   * @private
   *
   * Calculate the number of students who scored above, or at, the average
   * and those who did lower.
   *
   * @param  {Number} _avgScore
   * @param  {Number[]} scores
   *         The flattened score percentile data-set (see #calculateChartData()).
   *
   * @return {Object} out
   * @return {Number} out.aboveAverage
   * @return {Number} out.belowAverage
   */
  calculateStudentStatistics(_avgScore, scores) {
    const avgScore = Math.round(_avgScore)

    return {
      aboveAverage: scores
        .filter(function (__y, percentile) {
          return percentile >= avgScore
        })
        .reduce(function (count, y) {
          return count + y
        }, 0),

      belowAverage: scores
        .filter(function (__y, percentile) {
          return percentile < avgScore
        })
        .reduce(function (count, y) {
          return count + y
        }, 0),
    }
  },

  /**
   * @private
   */
  calculateChartData(props) {
    let percentile
    const set = []
    const scores = props.scores || {}
    const highest = max(
      Object.keys(scores).map(function (score) {
        return parseInt(score, 10)
      })
    )

    const upperBound = max([101, highest])

    for (percentile = 0; percentile < upperBound; ++percentile) {
      set[percentile] = scores['' + percentile] || 0
    }

    // merge right outliers with 100%
    set[100] = sum(set.splice(100, set.length))

    return set
  },
})

ScorePercentileChart.displayName = 'ScorePercentileChart'
ScorePercentileChart.defaultProps = {
  scores: {},
  animeDelay: 500,
  animeDuration: 500,
  width: 960,
  height: 220,
  barPadding: 0.25,
  minBarHeight: 1,
  numTicks: 5,
}

ScorePercentileChart.propTypes = {
  scores: PropTypes.object,
  scoreAverage: PropTypes.number,
  pointsPossible: PropTypes.number,
}

export default ScorePercentileChart
