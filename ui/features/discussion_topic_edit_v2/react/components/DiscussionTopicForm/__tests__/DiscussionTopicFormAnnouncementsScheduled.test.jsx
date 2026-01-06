/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Announcements Scheduled', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  // InstUI DateTimeInput's initialTimeForNewDate prop only applies when using the
  // calendar picker to select a date, not when typing directly into the input field.
  // This test would need to use the calendar picker UI to verify this behavior.
  it.skip('sets the default time to EOD for end time ', async () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.course_published = false
    window.ENV.TIMEZONE = 'America/Denver'

    const document = setup()

    const dateInput = document.getByTestId('announcement-available-until-date')

    await userEvent.click(dateInput)
    await userEvent.type(dateInput, '09/30/2025')

    // Trigger blur to ensure the date change is processed
    fireEvent.blur(dateInput)

    const timeInput = await document.findByTestId('announcement-available-until-time')

    await waitFor(() => {
      expect(timeInput.value).toBe('11:59 PM')
    })
  })

  it(
    'sets the default time to BOD for start time ',
    async () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.course_published = false
      window.ENV.TIMEZONE = 'America/Denver'

      const document = setup()

      const dateInput = document.getByTestId('announcement-available-from-date')

      await userEvent.click(dateInput)
      await userEvent.type(dateInput, '09/30/2025')

      // Trigger blur to ensure the date change is processed
      fireEvent.blur(dateInput)

      const timeInput = await document.findByTestId('announcement-available-from-time')

      await waitFor(() => {
        expect(timeInput.value).toBe('12:00 AM')
      })
    },
    {timeout: 10000},
  )

  it(
    'does not show info alert when creating a scheduled announcement in a published course',
    async () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.course_published = true

      const document = setup()

      const dateInput = document.getByTestId('announcement-available-from-date')

      await userEvent.click(dateInput)
      await userEvent.type(dateInput, '09/30/2025')
      fireEvent.blur(dateInput)

      expect(document.queryByTestId('schedule-info-alert')).toBeFalsy()
    },
    {timeout: 10000},
  )
})
