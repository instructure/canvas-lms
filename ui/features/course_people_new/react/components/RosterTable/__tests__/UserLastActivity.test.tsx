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
import {render} from '@testing-library/react'
import UserLastActivity from '../UserLastActivity'
import {timeEventToString} from '../../../../util/utils'
import {OBSERVER_ENROLLMENT} from '../../../../util/constants'
import {mockEnrollment} from '../../../../graphql/Mocks'

jest.mock('../../../../util/utils', () => ({
  timeEventToString: jest.fn(() => 'Feb 18, 2025 at 12:00pm')
}))

describe('UserLastActivity', () => {
  const mockedLastActivity = 'Feb 18, 2025 at 12:00pm'
  const defaultEnrollments = [
    mockEnrollment({enrollmentId: '1'}),
    mockEnrollment({enrollmentId: '2', lastActivityAt: '2025-02-17T10:17:35-06:00'})
  ]

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders last activity dates for valid enrollments', () => {
    const {getAllByText} = render(<UserLastActivity enrollments={defaultEnrollments} />)
    const activities = getAllByText(mockedLastActivity)
    expect(activities).toHaveLength(2)
    expect(timeEventToString).toHaveBeenCalledTimes(2)
  })

  it('filters out observer enrollments', () => {
    const enrollmentsWithObserver = [
      mockEnrollment({enrollmentId: '1'}),
      mockEnrollment({enrollmentId: '2', enrollmentType: OBSERVER_ENROLLMENT})
    ]
    const {getAllByText} = render(<UserLastActivity enrollments={enrollmentsWithObserver} />)
    const activities = getAllByText(mockedLastActivity)
    expect(activities).toHaveLength(1)
    expect(timeEventToString).toHaveBeenCalledTimes(1)
  })

  it('skips enrollments without last activity', () => {
    const enrollmentsNoLastActivity = [defaultEnrollments[0], {...defaultEnrollments[1], lastActivityAt: null}]
    const {getAllByText} = render(<UserLastActivity enrollments={enrollmentsNoLastActivity} />)
    const activities = getAllByText(mockedLastActivity)
    expect(activities).toHaveLength(1)
    expect(timeEventToString).toHaveBeenCalledTimes(1)
  })

  it('formats dates with correct parameters', () => {
    render(<UserLastActivity enrollments={defaultEnrollments} />)
    expect(timeEventToString).toHaveBeenCalledWith(defaultEnrollments[0].lastActivityAt)
    expect(timeEventToString).toHaveBeenCalledWith(defaultEnrollments[1].lastActivityAt)
  })

  it('handles empty enrollments array', () => {
    const {container} = render(<UserLastActivity enrollments={[]} />)
    expect(container).toBeEmptyDOMElement()
    expect(timeEventToString).not.toHaveBeenCalled()
  })

  it('renders last activity for each enrollment', () => {
    const {getAllByTestId} = render(<UserLastActivity enrollments={defaultEnrollments} />)
    const lastActivity = getAllByTestId(/last-activity-\d+/)
    expect(lastActivity).toHaveLength(2)
  })
})
