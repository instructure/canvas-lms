/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import CourseNotificationSettings from '../CourseNotificationSettings'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'

describe('Course Notification Settings', () => {
  it('renders the correct message', () => {
    const {getByText, getByTestId} = render(<CourseNotificationSettings />)

    expect(getByTestId('enable-notifications-toggle')).toBeInTheDocument()
    expect(
      getByText(
        'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()

    fireEvent.click(getByTestId('enable-notifications-toggle'))
    expect(
      getByText(
        'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })
})
