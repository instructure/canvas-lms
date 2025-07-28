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
import mockedNotificationPreferences from './MockedNotificationPreferences'
import NotificationPreferencesTable from '../Table'
import {render} from '@testing-library/react'
import {within} from '@testing-library/dom'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'

const category = 0
const commsChannel1 = 1
const commsChannel2 = 2
const commsChannel3 = 3

describe('Notification Preferences Table', () => {
  beforeEach(() => {
    fakeENV.setup({
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: {
          label: 'Some Label Text',
        },
        allowed_push_categories: ['announcement'],
      },
      current_user_roles: [],
      discussions_reporting: false,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('does not render the send scores in emails toggle if the env var is null', () => {
    fakeENV.setup({
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: null,
        allowed_push_categories: [],
      },
      current_user_roles: [],
      discussions_reporting: false,
    })

    const {getByTestId, queryByText} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const gradingCategory = getByTestId('grading')
    expect(gradingCategory).not.toBeNull()
    expect(queryByText('Some Label Text')).toBeNull()
  })

  it('renders the send scores toggle if the env var is set', () => {
    const {getByTestId, getByText} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const gradingCategory = getByTestId('grading')
    expect(gradingCategory).not.toBeNull()
    expect(getByText('Some Label Text')).toBeInTheDocument()
  })

  it('correctly disables deprecated categories for sms', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].children[0].textContent).toEqual('Due Date')
    expect(
      dueDateCategory.children[commsChannel2].querySelector('svg[name="IconNo"]'),
    ).toBeInTheDocument()
  })

  it('correctly disables restricted categories for push', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].children[0].textContent).toEqual('Due Date')
    expect(
      dueDateCategory.children[commsChannel3].querySelector('svg[name="IconNo"]'),
    ).toBeInTheDocument()
  })

  it('uses the notification policy overrides over the global policies if available', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const dueDateCategory = getByTestId('due_date')
    expect(dueDateCategory).not.toBeNull()
    expect(dueDateCategory.children[category].children[0].textContent).toEqual('Due Date')
    expect(
      dueDateCategory.children[commsChannel1].querySelector('svg[name="IconMuted"]'),
    ).toBeInTheDocument()
  })

  it('displays the path and path type correctly for push', () => {
    const {getByText} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    expect(getByText('Push Notification')).toBeInTheDocument()
    expect(getByText('For All Devices')).toBeInTheDocument()
  })

  it('only renders the category groups and categories that it is given', () => {
    const {queryByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    expect(queryByTestId('courseActivities')).not.toBeNull()
    expect(queryByTestId('conversations')).toBeNull()
  })

  it('renders the category description', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const dueDateDescription = getByTestId('due_date_description')
    const {getByText} = within(dueDateDescription)

    expect(dueDateDescription).not.toBeNull()
    expect(dueDateDescription).toContainElement(getByText('Due date description'))
  })

  it('removes <p> tags from descriptions', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={{
          sendScoresInEmails: true,
          channels: [
            {
              _id: '1',
              path: 'test@test.com',
              pathType: 'email',
              notificationPolicies: [
                {
                  communicationChannelId: '1',
                  frequency: 'daily',
                  notification: {
                    category: 'Due Date',
                    categoryDisplayName: 'Due Date',
                    categoryDescription: '<p>Due date description</p>',
                    name: 'Assignment Due Date Override Changed',
                    _id: '3',
                  },
                },
              ],
            },
          ],
        }}
        updatePreference={jest.fn()}
      />,
    )

    const dueDateDescription = getByTestId('due_date_description')
    const {queryByText} = within(dueDateDescription)

    expect(dueDateDescription).not.toBeNull()
    expect(dueDateDescription).toContainElement(queryByText('Due date description'))
    expect(dueDateDescription).not.toContainElement(queryByText('<p>Due date description</p>'))
  })

  it('renders the send scores in emails toggle as enabled when the setting is set', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const sendScoresToggle = getByTestId('grading-send-score-in-email')
    expect(sendScoresToggle.checked).toBe(true)
  })

  it('renders the send scores in emails toggle as unabled when the setting is not set', () => {
    const {getByTestId} = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences({sendScoresInEmails: false})}
        updatePreference={jest.fn()}
      />,
    )

    const sendScoresToggle = getByTestId('grading-send-score-in-email')
    expect(sendScoresToggle.checked).toBe(false)
  })

  it('allows tabbing to the row headers', () => {
    const container = render(
      <NotificationPreferencesTable
        preferences={mockedNotificationPreferences()}
        updatePreference={jest.fn()}
      />,
    )

    const dueDate = container.getByTestId('due_date_header')
    expect(dueDate.tabIndex).toBe(0)
  })
})
