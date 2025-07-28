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
import LastActivity from '../LastActivity'

describe('LastActivity', () => {
  const lastActivity = '2016-11-16T00:29:34Z'
  const createUser = (enrollments = []) => ({
    enrollments,
  })

  it('renders nothing when user has no enrollments', () => {
    const {container} = render(<LastActivity user={createUser()} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders nothing when user has enrollments but no last activity', () => {
    const user = createUser([{last_activity_at: null}])
    const {container} = render(<LastActivity user={user} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('displays the most recent activity from multiple enrollments', () => {
    const firstActivity = '2016-11-14T00:29:34Z'
    const middleActivity = '2016-11-15T00:29:34Z'
    const user = createUser([
      {last_activity_at: lastActivity},
      {last_activity_at: firstActivity},
      {last_activity_at: middleActivity},
    ])

    const {getByText, getByTestId} = render(<LastActivity user={user} />)

    expect(getByText('Last login:')).toBeInTheDocument()
    const friendlyDateTime = getByTestId('friendly-date-time')
    expect(friendlyDateTime).toBeInTheDocument()
    expect(friendlyDateTime.querySelector('time')).toHaveAttribute(
      'datetime',
      expect.stringContaining('2016-11-16'),
    )
  })

  it('displays a single enrollment activity', () => {
    const user = createUser([{last_activity_at: lastActivity}])
    const {getByText, getByTestId} = render(<LastActivity user={user} />)

    expect(getByText('Last login:')).toBeInTheDocument()
    const friendlyDateTime = getByTestId('friendly-date-time')
    expect(friendlyDateTime).toBeInTheDocument()
    expect(friendlyDateTime.querySelector('time')).toHaveAttribute(
      'datetime',
      expect.stringContaining('2016-11-16'),
    )
  })
})
