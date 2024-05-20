/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {View} from '@canvas/backbone'
import {extend as lodashExtend, each, map, filter, find} from 'lodash'
import Popover from 'jquery-popover'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import d3 from 'd3'
import I18n from '@canvas/i18n'
import popover_template from '@canvas/outcomes/jst/outcomePopover.handlebars'

extend(OutcomeColumnView, View)

function OutcomeColumnView() {
  this.mouseleave = this.mouseleave.bind(this)
  this.mouseenter = this.mouseenter.bind(this)
  return OutcomeColumnView.__super__.constructor.apply(this, arguments)
}

OutcomeColumnView.prototype.popover_template = popover_template

OutcomeColumnView.optionProperty('totalsFn')

OutcomeColumnView.prototype.inside = false

OutcomeColumnView.prototype.TIMEOUT_LENGTH = 50

OutcomeColumnView.prototype.events = {
  mouseenter: 'mouseenter',
  mouseleave: 'mouseleave',
}

OutcomeColumnView.prototype.account_level_scales = function () {
  return (this._account_level_scales = ENV.GRADEBOOK_OPTIONS.ACCOUNT_LEVEL_MASTERY_SCALES)
}

OutcomeColumnView.prototype.createPopover = function (e) {
  this.totalsFn()
  if (!this.account_level_scales()) {
    this.pickColors()
  }
  const attributes = lodashExtend(new Outcome(this.attributes).present(), {
    account_level_scales: this.account_level_scales(),
  })
  const popover = new Popover(e, this.popover_template(attributes), {
    verticalSide: 'bottom',
    invertOffset: true,
  })
  popover.el.on('mouseenter', this.mouseenter)
  popover.el.on('mouseleave', this.mouseleave)
  this.renderChart()
  popover.show(e)
  return popover
}

OutcomeColumnView.prototype.mouseenter = function (e) {
  if (!this.popover) {
    this.popover = this.createPopover(e)
  }
  return (this.inside = true)
}

OutcomeColumnView.prototype.mouseleave = function (_e) {
  this.inside = false
  return setTimeout(
    (function (_this) {
      return function () {
        if (_this.inside || !_this.popover) {
          return
        }
        _this.popover.hide()
        return delete _this.popover
      }
    })(this),
    this.TIMEOUT_LENGTH
  )
}

OutcomeColumnView.prototype.pickColors = function () {
  const data = this.attributes.ratings
  if (!data) {
    return
  }
  const last = data.length - 1
  const mastery = this.attributes.mastery_points
  const mastery_pos = data.indexOf(
    find(data, function (x) {
      return x.points === mastery
    })
  )
  const color = d3.scale
    .linear()
    .domain([0, mastery_pos, (mastery_pos + last) / 2, last])
    .range(['#416929', '#8bab58', '#e0d670', '#dd5c5c'])
  each(data, function (rating, i) {
    rating.color = color(i)
  })
}

OutcomeColumnView.prototype.renderChart = function () {
  this.data = filter(this.attributes.ratings, function (rating) {
    return rating.percent
  })
  this.r = 50
  this.arc = d3.svg.arc().outerRadius(this.r)
  this.arcs = this.renderArcs()
  this.renderArcFills()
  this.renderLabels()
  return this.renderLabelLines()
}

OutcomeColumnView.prototype.renderArcs = function () {
  const w = 160
  const h = 150
  const vis = d3
    .select('.outcome-details .chart-image')
    .append('svg:svg')
    .data([this.data])
    .attr('width', w)
    .attr('height', h)
    .append('svg:g')
    .attr('transform', 'translate(' + w / 2 + ', ' + h / 2 + ')')
  const pie = d3.layout.pie().value(function (d) {
    return d.percent
  })
  const arcs = vis.selectAll('g.slice').data(pie).enter().append('svg:g').attr('class', 'slice')
  return arcs
}

OutcomeColumnView.prototype.renderArcFills = function () {
  const initialRadius = 10
  const k = d3.interpolate(initialRadius, this.r)
  const arc = this.arc
  const radiusTween = function (a) {
    return function (t) {
      return arc.outerRadius(k(t))(a)
    }
  }
  this.arc.outerRadius(initialRadius)
  this.arcs
    .append('svg:path')
    .attr(
      'fill',
      (function (_this) {
        return function (d, i) {
          if (_this.account_level_scales()) {
            return '#' + _this.data[i].color
          } else {
            return _this.data[i].color
          }
        }
      })(this)
    )
    .attr('d', this.arc)
    .transition()
    .duration(400)
    .attrTween('d', radiusTween)
  return this.arc.outerRadius(this.r)
}

OutcomeColumnView.prototype.renderLabels = function () {
  return this.arcs
    .append('svg:text')
    .attr('fill', '#4F5F6E')
    .attr(
      'transform',
      (function (_this) {
        return function (d) {
          let c = _this.getCentroid(d)
          c = map(c, function (x) {
            return x * 2.3
          })
          return 'translate(' + c + ')'
        }
      })(this)
    )
    .attr(
      'text-anchor',
      (function (_this) {
        return function (d) {
          const ref = _this.getAngleInfo(d)
          const angle = ref.angle
          const distanceToPi = ref.distanceToPi
          if (distanceToPi < Math.PI / 6) {
            return 'middle'
          }
          if (angle > Math.PI) {
            return 'end'
          } else {
            return 'start'
          }
        }
      })(this)
    )
    .attr(
      'dominant-baseline',
      (function (_this) {
        return function (d) {
          const ref = _this.getAngleInfo(d, true)
          const angle = ref.angle
          const distanceToPi = ref.distanceToPi
          if (distanceToPi < Math.PI / 6) {
            return 'middle'
          }
          if (angle > Math.PI) {
            return 'hanging'
          } else {
            return 'auto'
          }
        }
      })(this)
    )
    .text(
      (function (_this) {
        return function (d, i) {
          return I18n.n(_this.data[i].percent, {
            percentage: true,
          })
        }
      })(this)
    )
}

OutcomeColumnView.prototype.getAngleInfo = function (d, sideways) {
  let angle = (d.endAngle + d.startAngle) / 2
  if (sideways) {
    angle = (angle + Math.PI / 2) % (2 * Math.PI)
  }
  const distanceToPi = Math.abs(((angle + Math.PI / 2) % Math.PI) - Math.PI / 2)
  return {
    angle,
    distanceToPi,
  }
}

OutcomeColumnView.prototype.renderLabelLines = function () {
  return this.arcs
    .append('svg:path')
    .attr('stroke', '#000')
    .attr(
      'd',
      (function (_this) {
        return function (d) {
          const c = _this.getCentroid(d)
          const c1 = map(c, function (x) {
            return x * 1.4
          })
          const c2 = map(c, function (x) {
            return x * 2.2
          })
          return 'M' + c1[0] + ' ' + c1[1] + ' L' + c2[0] + ' ' + c2[1]
        }
      })(this)
    )
}

OutcomeColumnView.prototype.getCentroid = function (d) {
  d.innerRadius = 0
  d.outerRadius = this.r
  return this.arc.centroid(d)
}

export default OutcomeColumnView
