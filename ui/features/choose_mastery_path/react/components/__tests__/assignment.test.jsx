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
import {render} from '@testing-library/react'
import Assignment from '../assignment'

const defaultProps = () => ({
  isSelected: false,
  assignment: {
    name: 'Ch 2 Quiz',
    type: 'quiz',
    points_possible: 10,
    due_at: new Date(),
    itemId: 1,
    description: 'a quiz',
    category: {
      id: 'other',
      label: 'Other',
    },
  },
})

describe('Assignment', () => {
  it('renders the assignment component', () => {
    const props = defaultProps()
    const {container} = render(<Assignment {...props} />)

    const assignment = container.querySelector('.cmp-assignment')
    expect(assignment).toBeInTheDocument()
  })

  it('displays the assignment title correctly', () => {
    const props = defaultProps()
    const {getByText} = render(<Assignment {...props} />)

    expect(getByText('Ch 2 Quiz')).toBeInTheDocument()
  })

  it('shows points when points_possible is provided', () => {
    const props = defaultProps()
    const {getByText} = render(<Assignment {...props} />)

    expect(getByText('10 pts')).toBeInTheDocument()
  })

  it('hides points when points_possible is null', () => {
    const props = defaultProps()
    props.assignment.points_possible = null
    const {container} = render(<Assignment {...props} />)

    const pointsDisplay = container.querySelector('.points_possible_display')
    expect(pointsDisplay).not.toBeInTheDocument()
  })

  it('renders a link title when assignment is selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const {container} = render(<Assignment {...props} />)

    const titleLink = container.querySelector('.cmp-assignment__title-link')
    expect(titleLink).toBeInTheDocument()
  })

  it('displays the assignment description', () => {
    const props = defaultProps()
    const {container} = render(<Assignment {...props} />)

    const description = container.querySelector('.ig-description')
    expect(description).toBeInTheDocument()
  })

  it('shows the assignment type icon', () => {
    const props = defaultProps()
    const {container} = render(<Assignment {...props} />)

    const typeIcon = container.querySelector('.ig-type-icon')
    expect(typeIcon).toBeInTheDocument()
  })

  it('shows the due date when provided', () => {
    const props = defaultProps()
    const {getByText} = render(<Assignment {...props} />)

    expect(getByText('Due')).toBeInTheDocument()
  })

  it('shows the category label', () => {
    const props = defaultProps()
    const {getByTitle} = render(<Assignment {...props} />)

    expect(getByTitle('Other')).toBeInTheDocument()
  })
})
