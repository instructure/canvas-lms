/** @jsx React.DOM */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps')
  var d3 = require('d3')
  var ChartMixin = require('../../../mixins/chart')

  var Chart = React.createClass({
    mixins: [ChartMixin.mixin],

    getDefaultProps: function() {
      return {
        correct: [],
        total: [],
        ratio: []
      }
    },

    createChart: function(node, props) {
      var barHeight, barWidth, svg

      barHeight = props.height / 3
      barWidth = props.width / 2

      svg = d3
        .select(node)
        .attr('width', props.width)
        .attr('height', props.height)
        .append('g')

      svg
        .selectAll('.bar.correct')
        .data(props.ratio)
        .enter()
        .append('rect')
        .attr('class', 'bar correct')
        .attr('x', barWidth)
        .attr('width', function(correctRatio) {
          return correctRatio * barWidth
        })
        .attr('y', function(d, bracket) {
          return bracket * barHeight
        })
        .attr('height', function() {
          return barHeight - 1
        })

      svg
        .selectAll('.bar.incorrect')
        .data(props.ratio)
        .enter()
        .append('rect')
        .attr('class', 'bar incorrect')
        .attr('x', function(correctRatio) {
          return -1 * (1 - correctRatio * barWidth)
        })
        .attr('width', function(correctRatio) {
          return (1 - correctRatio) * barWidth
        })
        .attr('y', function(d, bracket) {
          return bracket * barHeight
        })
        .attr('height', function() {
          return barHeight - 1
        })

      this.__svg = svg

      return svg
    },

    render: ChartMixin.defaults.render
  })

  return Chart
})
