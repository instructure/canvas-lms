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

import {fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Announcements Scheduled', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  it(
    'shows info alert when creating a scheduled announcement in an unpublished course',
    async () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.course_published = false

      const document = setup()

      const dateInput = document.getByTestId('announcement-available-from-date')

      await userEvent.click(dateInput)
      await userEvent.type(dateInput, '09/30/2025')
      fireEvent.blur(dateInput)

      expect(await document.findByTestId('schedule-info-alert')).toHaveTextContent(
        'Notifications will only be sent to students who have been enrolled. Please allow time for this process to finish after publishing your course before scheduling this announcement.',
      )
    },
    {timeout: 10000},
  )
})
