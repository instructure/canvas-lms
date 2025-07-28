/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import AssignmentItem from '../student-assignment-item'

describe('Student Assignment Item', () => {
  const defaultProps = () => ({
    assignment: {
      name: 'hello world',
      grading_type: 'percent',
      points_possible: 100,
      submission_types: ['online_text_entry'],
    },
    trend: 0,
    score: 0.8,
  })

  it('renders assignment item correctly', () => {
    const {container} = render(<AssignmentItem {...defaultProps()} />)
    const assignmentElements = container.querySelectorAll('.crs-student-details__assignment')
    expect(assignmentElements).toHaveLength(1)
    expect(assignmentElements[0]).toBeInTheDocument()
  })

  it('renders bar inner-components correctly', () => {
    const {container} = render(<AssignmentItem {...defaultProps()} />)
    const iconElements = container.querySelectorAll('.crs-student-details__assignment-icon')
    expect(iconElements).toHaveLength(1)
    expect(iconElements[0]).toBeInTheDocument()
  })

  it('renders name correctly', () => {
    const {container} = render(<AssignmentItem {...defaultProps()} />)
    const nameElements = container.querySelectorAll('.crs-student-details__assignment-name')
    expect(nameElements).toHaveLength(1)
    expect(nameElements[0]).toBeInTheDocument()
    expect(nameElements[0]).toHaveTextContent('hello world')
  })

  it('renders trend icon', () => {
    const {container} = render(<AssignmentItem {...defaultProps()} />)
    const trendElements = container.querySelectorAll('.crs-student__trend-icon')
    expect(trendElements).toHaveLength(1)
    expect(trendElements[0]).toBeInTheDocument()
  })

  it('renders correct icon type', () => {
    const {container} = render(<AssignmentItem {...defaultProps()} />)
    const assignmentIcons = container.querySelectorAll('.icon-assignment')
    expect(assignmentIcons).toHaveLength(1)
    expect(assignmentIcons[0]).toBeInTheDocument()
  })

  it('renders no trend correctly', () => {
    const props = defaultProps()
    props.trend = null
    const {container} = render(<AssignmentItem {...props} />)
    const trendElements = container.querySelectorAll('.crs-student__trend-icon')
    expect(trendElements).toHaveLength(0)
  })

  it('renders positive trend correctly', () => {
    const props = defaultProps()
    props.trend = 1
    const {container} = render(<AssignmentItem {...props} />)
    const positiveTrendElements = container.querySelectorAll('.crs-student__trend-icon__positive')
    expect(positiveTrendElements).toHaveLength(1)
    expect(positiveTrendElements[0]).toBeInTheDocument()
  })

  it('renders neutral trend correctly', () => {
    const props = defaultProps()
    props.trend = 0
    const {container} = render(<AssignmentItem {...props} />)
    const neutralTrendElements = container.querySelectorAll('.crs-student__trend-icon__neutral')
    expect(neutralTrendElements).toHaveLength(1)
    expect(neutralTrendElements[0]).toBeInTheDocument()
  })

  it('renders negative trend correctly', () => {
    const props = defaultProps()
    props.trend = -1
    const {container} = render(<AssignmentItem {...props} />)
    const negativeTrendElements = container.querySelectorAll('.crs-student__trend-icon__negative')
    expect(negativeTrendElements).toHaveLength(1)
    expect(negativeTrendElements[0]).toBeInTheDocument()
  })
})
