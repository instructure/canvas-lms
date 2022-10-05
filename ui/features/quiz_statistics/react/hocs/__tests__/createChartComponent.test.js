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

import {render} from '@testing-library/react'
import React from 'react'
import createChartComponent from '../createChartComponent'
import assertChange from 'chai-assert-change'

describe('canvas_quizzes/statistics/createChartComponent', () => {
  it('works', () => {
    const chartNode = document.createElement('svg')
    const Chart = createChartComponent({
      createChart: (node, props) => {
        Object.assign(chartNode.style, props.style)
        return chartNode
      },
    })

    render(<Chart style={{width: '10px'}} />)

    expect(chartNode.style.width).toBe('10px')
  })

  it('calls updateChart with new props', () => {
    const chartNode = document.createElement('svg')
    const createChart = jest.fn(() => chartNode)
    const updateChart = jest.fn()
    const Chart = createChartComponent({
      createChart,
      updateChart,
    })

    const {rerender} = render(<Chart style={{width: '10px'}} />)

    assertChange({
      fn: () => rerender(<Chart style={{width: '15px'}} />),
      in: [
        {
          of: () => createChart.mock.calls.length,
          by: 0,
        },
        {
          of: () => updateChart.mock.calls.length,
          by: 1,
        },
      ],
    })
  })

  it('calls removeChart on removal', () => {
    const removeChart = jest.fn()
    const Chart = createChartComponent({
      createChart: () => document.createElement('svg'),
      removeChart,
    })

    const {unmount} = render(<Chart style={{width: '10px'}} />)

    assertChange({
      fn: () => unmount(),
      of: () => removeChart.mock.calls.length,
      by: 1,
    })
  })
})
