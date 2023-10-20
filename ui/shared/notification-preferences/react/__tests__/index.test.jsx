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

import NotificationPreferences from '../index'
import {render} from '@testing-library/react'
import React from 'react'

function defaultProps(overrides) {
  return {
    contextType: 'course',
    contextName: 'Course01',
    enabled: false,
    updatePreference: jest.fn(),
    userId: '1',
    notificationPreferences: {channels: []},
    ...overrides,
  }
}

const privacyNoticeText =
  'Notice: Some notifications may contain confidential information. Selecting to receive notifications at an email other than your institution provided address may result in sending sensitive Canvas course and group information outside of the institutional system.'

describe('Notification Preferences', () => {
  it('renders the context name next to mute toggle', () => {
    const props = defaultProps()

    const {getByText} = render(<NotificationPreferences {...props} />)

    expect(getByText('Enable Notifications for Course01')).toBeInTheDocument()
  })

  it('renders notification times with a close button', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        daily_notification_time: '6pm',
        weekly_notification_range: {
          weekday: 'Saturday',
          start_time: '7pm',
          end_time: '9pm',
        },
      },
    }
    const props = defaultProps()
    const {getByTestId} = render(<NotificationPreferences {...props} />)

    const notification_times = getByTestId('notification_times')
    expect(notification_times).not.toBeNull()
    expect(notification_times.textContent).toEqual(
      'Daily notifications will be delivered around 6pm. Weekly notifications will be delivered Saturday between 7pm and 9pm.Close'
    )
  })

  it('does not render notification times if env: weekly_notification_range is not set', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: null,
        allowed_push_categories: [],
        daily_notification_time: '6pm',
      },
    }

    const props = defaultProps()
    const {queryByTestId} = render(<NotificationPreferences {...props} />)

    const notification_times = queryByTestId('notification_times')
    expect(notification_times).toBeNull()
  })

  it('does not render notification times if env: daily_notification_time is not set', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: null,
        allowed_push_categories: [],
        weekly_notification_range: {
          weekday: 'Saturday',
          start_time: '7pm',
          end_time: '9pm',
        },
      },
    }

    const props = defaultProps()
    const {queryByTestId} = render(<NotificationPreferences {...props} />)

    const notification_times = queryByTestId('notification_times')
    expect(notification_times).toBeNull()
  })

  it('renders the appropriate alert text for course context', () => {
    const props = defaultProps()
    const {getByText} = render(<NotificationPreferences {...props} />)

    expect(
      getByText(
        'Course-level notifications are inherited from your account-level notification settings. Adjusting notifications for this course will override notifications at the account level.'
      )
    ).toBeInTheDocument()
  })

  it('renders the appropriate alert text for account context', () => {
    const props = defaultProps({
      contextType: 'account',
      contextName: 'Dope Account',
    })
    const {getByText} = render(<NotificationPreferences {...props} />)

    expect(
      getByText(
        'Account-level notifications apply to all courses. Notifications for individual courses can be changed within each course and will override these notifications.'
      )
    ).toBeInTheDocument()
  })

  it('renders the Privacy Notice alert when enabled by domain account', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        account_privacy_notice: true,
      },
    }

    const props = defaultProps({
      contextType: 'account',
      contextName: 'Dope Account',
    })
    const {getByText} = render(<NotificationPreferences {...props} />)

    expect(getByText(privacyNoticeText)).toBeInTheDocument()
  })

  it('does not render the Privacy Notice alert when context is course', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        account_privacy_notice: true,
      },
    }

    const props = defaultProps({
      contextType: 'course',
      contextName: 'Dope Course',
    })
    const {queryByText} = render(<NotificationPreferences {...props} />)

    expect(queryByText(privacyNoticeText)).not.toBeInTheDocument()
  })

  it('does not render the Privacy Notice alert when it has been read', () => {
    window.ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        account_privacy_notice: true,
        read_privacy_info: 'some date string',
      },
    }

    const props = defaultProps({
      contextType: 'account',
      contextName: 'Dope Account',
    })
    const {queryByText} = render(<NotificationPreferences {...props} />)

    expect(queryByText(privacyNoticeText)).not.toBeInTheDocument()
  })

  it('renders the observer toggle if sendObservedNamesInNotifications prop is present', () => {
    const props = defaultProps({
      contextType: 'account',
      contextName: 'Cool Account',
      notificationPreferences: {
        channels: [],
        sendObservedNamesInNotifications: true,
      },
    })
    const {getByTestId} = render(<NotificationPreferences {...props} />)

    expect(getByTestId('send-observed-names-toggle')).toBeInTheDocument()
  })

  it('does not render the observer toggle if sendObservedNamesInNotifications prop is missing', () => {
    const props = defaultProps({
      contextType: 'account',
      contextName: 'Cool Account',
      notificationPreferences: {
        channels: [],
        sendObservedNamesInNotifications: null,
      },
    })
    const {queryByTestId} = render(<NotificationPreferences {...props} />)

    expect(queryByTestId('send-observed-names-toggle')).not.toBeInTheDocument()
  })
})
