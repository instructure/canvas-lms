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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import DisallowThreadedFixAlert from '../DisallowThreadedFixAlert'

describe('DisallowThreadedFixAlert', () => {
  beforeEach(() => {
    window.ENV = {
      COURSE_ID: '1',
      permissions: {
        moderate: true,
      },
      HAS_SIDE_COMMENT_DISCUSSIONS: true,
      current_context: {
        type: 'Course',
      },
    }
  })

  afterEach(() => {
    window.localStorage.removeItem('disallow_threaded_fix_alert_dismissed_1')
  })

  it('renders the alert and buttons', () => {
    const {getByText} = render(<DisallowThreadedFixAlert />)
    expect(getByText(/around disallowing threaded replies/)).toBeInTheDocument()
    expect(getByText('Dismiss')).toBeInTheDocument()
    expect(getByText('Make All Discussions Threaded')).toBeInTheDocument()
  })

  it('does not render the alert if the user does not have permissions', () => {
    window.ENV.permissions.moderate = false
    const {queryByText} = render(<DisallowThreadedFixAlert />)
    expect(queryByText(/around disallowing threaded replies/)).not.toBeInTheDocument()
  })

  it('does not render the alert if the context is not a course', () => {
    window.ENV.current_context.type = 'Group'
    const {queryByText} = render(<DisallowThreadedFixAlert />)
    expect(queryByText(/around disallowing threaded replies/)).not.toBeInTheDocument()
  })

  it('does not render the alert if context has no side comment discussions', () => {
    window.ENV.HAS_SIDE_COMMENT_DISCUSSIONS = false
    const {queryByText} = render(<DisallowThreadedFixAlert />)
    expect(queryByText(/around disallowing threaded replies/)).not.toBeInTheDocument()
  })

  it('does not render the alert if the user already dismissed it', () => {
    window.localStorage.setItem('disallow_threaded_fix_alert_dismissed_1', 'true')
    const {queryByText} = render(<DisallowThreadedFixAlert />)
    expect(queryByText(/around disallowing threaded replies/)).not.toBeInTheDocument()
  })

  it('renders the alert if the user dismissed it in another course', () => {
    window.localStorage.setItem('disallow_threaded_fix_alert_dismissed_2', 'true')
    const {getByText} = render(<DisallowThreadedFixAlert />)
    expect(getByText(/around disallowing threaded replies/)).toBeInTheDocument()
  })

  it('opens confirmation modal when "Make All Discussions Threaded" is clicked', async () => {
    const {getByText, getByTestId, queryAllByText} = render(<DisallowThreadedFixAlert />)
    const updateAllButton = getByTestId('disallow_threaded_fix_alert_update_all')
    await userEvent.click(updateAllButton)
    expect(queryAllByText('Make All Discussions Threaded')).toHaveLength(3) // alert button, modal title, confirm button
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('dismisses the alert when "Dismiss" is clicked', async () => {
    const {queryByText, getByTestId} = render(<DisallowThreadedFixAlert />)
    const dismissButton = getByTestId('disallow_threaded_fix_alert_dismiss')
    expect(window.localStorage.getItem('disallow_threaded_fix_alert_dismissed_1')).toBeNull()
    await userEvent.click(dismissButton)
    await waitFor(() =>
      expect(queryByText(/around disallowing threaded replies/)).not.toBeInTheDocument(),
    )
    expect(window.localStorage.getItem('disallow_threaded_fix_alert_dismissed_1')).toBe('true')
  })
})
