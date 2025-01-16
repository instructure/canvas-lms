/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import BreakdownGraph from '../breakdown-graphs'

describe('BreakdownGraph', () => {
  const defaultProps = (overrides = {}) => ({
    ranges: [
      {
        scoring_range: {
          id: 1,
          rule_id: 1,
          lower_bound: 0.7,
          upper_bound: 1.0,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
      {
        scoring_range: {
          id: 3,
          rule_id: 1,
          lower_bound: 0.4,
          upper_bound: 0.7,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
      {
        scoring_range: {
          id: 2,
          rule_id: 1,
          lower_bound: 0.0,
          upper_bound: 0.4,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
    ],
    enrolled: 10,
    assignment: {
      id: 7,
      title: 'Points',
      description: '',
      points_possible: 15,
      grading_type: 'points',
      submission_types: 'on_paper',
      grading_scheme: null,
    },
    isLoading: false,
    selectRange: jest.fn(),
    openSidebar: jest.fn(),
    ...overrides,
  })

  it('renders the title', () => {
    const {getByRole} = render(<BreakdownGraph {...defaultProps()} />)
    expect(getByRole('heading', {name: 'Mastery Paths Breakdown'})).toBeInTheDocument()
  })

  it('renders loading state correctly', () => {
    const props = defaultProps({isLoading: true})
    const {getByText, getByTitle} = render(<BreakdownGraph {...props} />)

    expect(getByTitle('Loading')).toBeInTheDocument()
    expect(getByText('Loading Data..')).toBeInTheDocument()
  })

  it('renders three bar components when not loading', () => {
    const {container} = render(<BreakdownGraph {...defaultProps()} />)
    const bars = container.getElementsByClassName('crs-bar__container')
    expect(bars).toHaveLength(3)
  })

  it('renders correct point ranges for each bar', () => {
    const {getAllByText} = render(<BreakdownGraph {...defaultProps()} />)

    expect(getAllByText('10.5 pts+ to 15 pts')).toHaveLength(1)
    expect(getAllByText('6 pts+ to 10.5 pts')).toHaveLength(1)
    expect(getAllByText('0 pts+ to 6 pts')).toHaveLength(1)
  })

  it('renders student counts correctly', () => {
    const props = defaultProps({
      ranges: defaultProps().ranges.map(range => ({...range, size: 2})),
    })
    const {getAllByText} = render(<BreakdownGraph {...props} />)

    const studentCountButtons = getAllByText('2 out of 10 students')
    expect(studentCountButtons).toHaveLength(3)
  })

  it('calls selectRange when a bar is clicked', () => {
    const props = defaultProps()
    const {getAllByText} = render(<BreakdownGraph {...props} />)

    const firstBar = getAllByText('0 out of 10 students')[0]
    fireEvent.click(firstBar)
    expect(props.selectRange).toHaveBeenCalledWith(0)
  })

  it('calls openSidebar when a bar is clicked', () => {
    const props = defaultProps()
    const {getAllByText} = render(<BreakdownGraph {...props} />)

    const firstBar = getAllByText('0 out of 10 students')[0]
    fireEvent.click(firstBar)
    expect(props.openSidebar).toHaveBeenCalled()
  })
})
