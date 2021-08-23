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

import React from 'react'
import invariant from 'invariant'

const createChartComponent = fns => {
  invariant(
    typeof fns.createChart === 'function',
    'createChartComponent: you must define a createChart() method that returns a d3 element'
  )

  const fnsWithDefaults = {updateChart, removeChart, ...fns}

  return class extends React.Component {
    constructor(props) {
      super(props)

      this.chartRef = React.createRef()
      this.wrapperRef = React.createRef()

      for (const fn of Object.keys(fnsWithDefaults)) {
        this[fn] = fnsWithDefaults[fn].bind(this)
      }
    }

    componentDidMount() {
      this.__svg = this.createChart(this.chartRef.current, this.props)
    }

    shouldComponentUpdate(nextProps /* , nextState */) {
      this.updateChart(this.__svg, nextProps)
      return false
    }

    componentWillUnmount() {
      this.removeChart()
    }

    render() {
      return (
        <div ref={this.wrapperRef}>
          <svg className="chart" ref={this.chartRef} />
        </div>
      )
    }
  }
}

export default createChartComponent

export function addDescription(holder, description) {
  return holder
    .append('text')
    .attr('tabindex', '0')
    .attr('class', 'screenreader-only')
    .text(description)
}

export function addTitle(svg, title) {
  return svg.append('title').text(title)
}

function updateChart(svg, props) {
  this.removeChart()
  this.__svg = this.createChart(this.chartRef.current, props)
}

function removeChart() {
  if (this.__svg) {
    this.__svg.remove()
    delete this.__svg
  }
}
