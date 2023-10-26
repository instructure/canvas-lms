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
import {render} from '@testing-library/react'
import Gradebook from '../Gradebook'

describe('Gradebook', () => {
  const defaultProps = (props = {}) => {
    return {
      students: [
        {
          status: 'active',
          name: 'Student Test',
          display_name: 'Student Test',
          sortable_name: 'Test, Student',
          avatar_url: '/avatar-url',
          id: '1',
        },
        {
          status: 'active',
          name: 'Student Test 2',
          display_name: 'Student Test 2',
          sortable_name: 'Test 2, Student',
          avatar_url: '/avatar-url-2',
          id: '2',
        },
      ],
      outcomes: [
        {
          id: '1',
          title: 'outcome 1',
          description: 'Outcome description',
          display_name: 'Friendly outcome name',
          calculation_method: 'decaying_average',
          calculation_int: 65,
          mastery_points: 5,
          ratings: [],
        },
        {
          id: '2',
          title: 'outcome 2',
          description: 'Outcome description',
          display_name: 'Friendly outcome name',
          calculation_method: 'decaying_average',
          calculation_int: 65,
          mastery_points: 5,
          ratings: [],
        },
      ],
      rollups: [
        {
          studentId: '1',
          outcomeRollups: [],
        },
        {
          studentId: '2',
          outcomeRollups: [],
        },
      ],
      courseId: '100',
      visibleRatings: [true, true, true, true, true, true],
      gradebookFilters: [],
      gradebookFilterHandler: jest.fn(),
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = {GRADEBOOK_OPTIONS: {ACCOUNT_LEVEL_MASTERY_SCALES: true}}
  })

  it('renders each student', () => {
    const props = defaultProps()
    const {getByText} = render(<Gradebook {...props} />)
    props.students.forEach(student => {
      expect(getByText(student.display_name)).toBeInTheDocument()
    })
  })

  it('renders each outcome', () => {
    const props = defaultProps()
    const {getByText} = render(<Gradebook {...props} />)
    props.outcomes.forEach(outcome => {
      expect(getByText(outcome.title)).toBeInTheDocument()
    })
  })
})
