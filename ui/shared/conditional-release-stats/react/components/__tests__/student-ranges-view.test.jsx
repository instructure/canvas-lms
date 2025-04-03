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
import {render, screen} from '@testing-library/react'
import StudentRangesView from '../student-ranges-view'

// Suppress React key warning since we're not testing that functionality
const originalError = console.error
beforeAll(() => {
  console.error = (...args) => {
    if (args[0].includes('unique "key" prop')) return
    originalError.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalError
})

const defaultProps = {
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
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: ['on_paper'],
    grading_scheme: null,
  },
  selectedPath: {
    range: 0,
    student: null,
  },
  selectStudent: jest.fn(),
}

describe('StudentRangesView', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders three range components correctly', () => {
    render(<StudentRangesView {...defaultProps} />)

    // Verify header
    expect(screen.getByText('Mastery Paths Breakdown')).toBeInTheDocument()

    // Verify range toggle buttons
    const toggleButtons = screen.getAllByRole('button')
    expect(toggleButtons).toHaveLength(3)

    // Verify range labels
    expect(screen.getByText('> 10.5 pts - 15 pts')).toBeInTheDocument()
    expect(screen.getByText('> 6 pts - 10.5 pts')).toBeInTheDocument()
    expect(screen.getByText('> 0 pts - 6 pts')).toBeInTheDocument()

    // Verify first range is expanded by default
    const firstButton = screen.getByRole('button', {name: '> 10.5 pts - 15 pts'})
    expect(firstButton).toHaveAttribute('aria-expanded', 'true')

    // Verify first range content is visible
    const firstRangeContent = document.getElementById('Expandable___0')
    expect(firstRangeContent).toHaveClass('css-1u67g6d-toggleDetails__details')
  })
})
