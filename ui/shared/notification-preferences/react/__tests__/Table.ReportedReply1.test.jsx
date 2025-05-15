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
import mockedNotificationPreferences from './MockedNotificationPreferences'
import NotificationPreferencesTable from '../Table'
import {render} from '@testing-library/react'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Notification Preferences Table - Reported Reply', () => {
  beforeEach(() => {
    fakeENV.setup({
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: {
          label: 'Some Label Text',
        },
        allowed_push_categories: ['announcement'],
      },
      current_user_roles: [], // Not a teacher
      discussions_reporting: false,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('does not show the notification preference when not a teacher', () => {
    const container = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const test = container.queryByTestId('reported_reply_header')
    expect(test).toBeNull()
  })
})
