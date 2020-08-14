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
  beforeEach(() => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: {
          label: 'Some Label Text'
        },
        deprecate_sms_enabled: true,
        allowed_sms_categories: ['announcement', 'grading']
      }
    }
  })

  it('does not render the send scores in emails toggle if the env var is null', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: null,
        deprecate_sms_enabled: true,
        allowed_sms_categories: ['announcement', 'grading']
      }
    }

    const {getByTestId, queryByText} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const gradingCategory = getByTestId('grading')
    expect(gradingCategory).not.toBeNull()
    expect(queryByText('Some Label Text')).toBeNull()
  })

  it('renders the send scores toggle if the env var is set', () => {
    const {getByTestId, getByText} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const gradingCategory = getByTestId('grading')
    expect(gradingCategory).not.toBeNull()
    expect(getByText('Some Label Text')).toBeInTheDocument()
  })

  it('correctly disables deprecated categories for sms', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].textContent).toEqual('Due Date')
    expect(
      dueDateCategory.children[commsChannel2].querySelector('svg[name="IconNo"]')
    ).toBeInTheDocument()
  })

  it('uses the notification policy overrides over the global policies if available', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].textContent).toEqual('Due Date')
    expect(
      dueDateCategory.children[commsChannel1].querySelector('svg[name="IconMuted"]')
    ).toBeInTheDocument()
  })

  it('only renders the category groups and categories that it is given', () => {
    const {queryByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    expect(queryByTestId('courseActivities')).not.toBeNull()
    expect(queryByTestId('conversations')).toBeNull()
  })

  it('renders the category description', () => {
    const {getByTestId, getByText} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const dueDateTooltip = getByTestId('due_date_description')
    expect(dueDateTooltip).not.toBeNull()
    expect(dueDateTooltip).toContainElement(getByText('Due date description'))
  })

  it('renders the send scores in emails toggle as enabled when the setting is set', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable preferences={mockedNotificationPreferences()} />
    )

    const sendScoresToggle = getByTestId('grading-send-score-in-email')
    expect(sendScoresToggle.checked).toBe(true)
  })

  it('renders the send scores in emails toggle as unabled when the setting is not set', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences({sendScoresInEmails: false})}
      />
    )

    const sendScoresToggle = getByTestId('grading-send-score-in-email')
    expect(sendScoresToggle.checked).toBe(false)
  })
})
