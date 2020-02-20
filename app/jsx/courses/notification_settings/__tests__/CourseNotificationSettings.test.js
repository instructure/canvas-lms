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

import axios from 'axios'
import CourseNotificationSettings from '../CourseNotificationSettings'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'

beforeEach(() => {
  window.ENV = {
    COURSE: {
      id: 1337
    }
  }

  jest.spyOn(axios, 'get').mockReturnValue({
    status: 200,
    data: {enabled: true}
  })

  jest.spyOn(axios, 'put').mockImplementation((url, parameters) => {
    const resp = {
      status: 200,
      data: parameters
    }
    return Promise.resolve(resp)
  })
})

describe('Course Notification Settings', () => {
  it('renders the correct message', async () => {
    const {findByText, findByTestId} = render(<CourseNotificationSettings />)

    expect(await findByTestId('enable-notifications-toggle')).toBeInTheDocument()
    expect(
      await findByText(
        'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()

    fireEvent.click(await findByTestId('enable-notifications-toggle'))
    expect(
      await findByText(
        'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })
})
