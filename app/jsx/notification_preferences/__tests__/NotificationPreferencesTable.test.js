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
import mockedNotificationPreferences from './MockedNotificationPreferences'
import NotificationPreferencesTable from '../NotificationPreferencesTable'
import {render} from '@testing-library/react'
import React from 'react'

const category = 0
const commsChannel1 = 1
const commsChannel2 = 2

describe('Notification Preferences Table', () => {
  it('correctly disables deprecated categories for sms', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        deprecate_sms_enabled: true,
        allowed_sms_categories: ['announcement', 'grading']
      }
    }

    const {getByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences} />
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].textContent).toEqual('Due Date')
    expect(dueDateCategory.children[commsChannel2].textContent).toEqual('disabled')
  })

  it('uses the notification policy overrides over the global policies if available', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences} />
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].textContent).toEqual('Due Date')
    expect(dueDateCategory.children[commsChannel1].textContent).toEqual('never')
  })
})
