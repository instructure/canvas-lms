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
import {enrollments} from '../../../../util/mocks'

jest.mock('../../../../util/utils', () => ({
  timeEventToString: jest.fn(() => 'Jan 1, 2025 at 12:00pm')
}))

describe('UserLastActivity', () => {
  const defaultEnrollments = enrollments.slice(0,2)

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders last activity dates for valid enrollments', () => {
    const {getAllByText} = render(<UserLastActivity enrollments={defaultEnrollments} />)
    const activities = getAllByText('Jan 1, 2025 at 12:00pm')
    expect(activities).toHaveLength(2)
    expect(timeEventToString).toHaveBeenCalledTimes(2)
  })

  it('filters out observer enrollments', () => {
    const enrollmentsWithObserver = enrollments.slice(0,3).map(e => {
      if (e.id === '3') return {...e, type: 'ObserverEnrollment'}
      return e
    })
    const {getAllByText} = render(<UserLastActivity enrollments={enrollmentsWithObserver} />)
    const activities = getAllByText('Jan 1, 2025 at 12:00pm')
    expect(activities).toHaveLength(2)
    expect(timeEventToString).toHaveBeenCalledTimes(2)
  })

  it('skips enrollments with no/null last_activity', () => {
    const enrollmentsWithNull = enrollments.slice(0,3).map(e => {
      if (e.id === '3') return {...e, last_activity: null}
      return e
    })
    const {getAllByText} = render(<UserLastActivity enrollments={enrollmentsWithNull} />)
    const activities = getAllByText('Jan 1, 2025 at 12:00pm')
    expect(activities).toHaveLength(2)
    expect(timeEventToString).toHaveBeenCalledTimes(2)
  })

  it('formats dates with correct parameters', () => {
    render(<UserLastActivity enrollments={defaultEnrollments} />)
    expect(timeEventToString).toHaveBeenCalledWith('2025-01-01T12:00:00Z')
    expect(timeEventToString).toHaveBeenCalledWith('2025-01-02T12:00:00Z')
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
