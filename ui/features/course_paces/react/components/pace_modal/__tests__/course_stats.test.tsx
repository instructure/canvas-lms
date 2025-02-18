/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import { renderConnected } from '../../../__tests__/utils'
import '@testing-library/jest-dom'
import CourseStats from '../CourseStats'

import {
  BLACKOUT_DATES,
  COURSE_PACE_CONTEXT,
  DEFAULT_STORE_STATE,
  PRIMARY_PACE
} from '../../../__tests__/fixtures'
import { StoreState } from '../../../types'

describe('Pace Modal CourseStats', () => {
  it('Course Pace in Draft status', () => {
    const defaultStoreState: StoreState = {
      ...DEFAULT_STORE_STATE,
      original: {
        coursePace: {
          ...PRIMARY_PACE,
          workflow_state: 'unpublished'
        },
        blackoutDates: BLACKOUT_DATES
      }
    }

    const { getByTestId } = renderConnected(<CourseStats paceContext={COURSE_PACE_CONTEXT} />, defaultStoreState)
    const draftStatusElement = getByTestId('status-draft')

    expect(draftStatusElement).toBeInTheDocument()
  })

  it('Course Pace not in Draft status', () => {
    const { queryByTestId } = renderConnected(<CourseStats paceContext={COURSE_PACE_CONTEXT} />)
    const draftStatusElement = queryByTestId('status-draft')

    expect(draftStatusElement).not.toBeInTheDocument()
  })

  it('Assignment count is shown correctly', () => {
    const { getByTestId } = renderConnected(<CourseStats paceContext={COURSE_PACE_CONTEXT} />)
    const assignmentsCountElement = getByTestId('assignments-count')

    expect(assignmentsCountElement.textContent).toBe('Assignment Count:3')
  })

  it('Students Enrolled count is shown correctly', () => {
    const { getByTestId } = renderConnected(<CourseStats paceContext={COURSE_PACE_CONTEXT} />)
    const assignmentsCountElement = getByTestId('student-enrollment-count')

    expect(assignmentsCountElement.textContent).toBe('Students Enrolled:31')
  })
})
