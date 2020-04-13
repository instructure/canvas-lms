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
import I18n from 'i18n!notification_preferences'
import NotificationPreferencesShape from './NotificationPreferencesShape'
import React from 'react'

import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'

const formattedCategoryNames = {
  courseActivities: I18n.t('Course Activities'),
  discussions: I18n.t('Discussions'),
  conversations: I18n.t('Conversations'),
  scheduling: I18n.t('Scheduling'),
  groups: I18n.t('Groups'),
  conferences: I18n.t('Conferences'),
  alerts: I18n.t('Alerts')
}

const notificationCategories = {
  courseActivities: {
    'Due Date': {},
    'Grading Policies': {},
    'Course Content': {},
    Files: {},
    Announcement: {},
    'Announcement Created By You': {},
    Grading: {},
    Invitation: {},
    'All Submissions': {},
    'Late Grading': {},
    'Submission Comment': {},
    Blueprint: {}
  },
  discussions: {
    Discussion: {},
    DiscussionEntry: {}
  },
  conversations: {
    'Added To Conversation': {},
    'Conversation Message': {},
    'Conversation Created': {}
  },
  scheduling: {
    'Student Appointment Signups': {},
    'Appointment Signups': {},
    'Appointment Cancelations': {},
    'Appointment Availability': {},
    Calendar: {}
  },
  groups: {
    'Membership Update': {}
  },
  conferences: {
    'Recording Ready': {}
  },
  alerts: {
    Other: {},
    'Content Link Error': {},
    'Account Notification': {}
  }
}

const formatCategoryKey = category => {
  let categoryStrings = category.split(/(?=[A-Z])/)
  categoryStrings = categoryStrings.map(word => word[0].toLowerCase() + word.slice(1))
  return categoryStrings.join('_').replace(/\s/g, '')
}

const renderNotificationCategory = (
  notificationPreferences,
  notificationCategory,
  renderChannelHeader
) => (
  <Table
    caption={I18n.t('%{categoryName} notification preferences', {
      categoryName: formattedCategoryNames[notificationCategory]
    })}
    margin="medium 0"
    layout="fixed"
    key={notificationCategory}
  >
    <Table.Head>
      <Table.Row>
        <Table.ColHeader id={notificationCategory} width="16rem">
          <Text size="large">{formattedCategoryNames[notificationCategory]}</Text>
        </Table.ColHeader>
        {notificationPreferences.channels.map(channel => (
          <Table.ColHeader
            textAlign="center"
            id={`${notificationCategory}-${channel.path}`}
            key={`${notificationCategory}-${channel.path}`}
            width="8rem"
          >
            {renderChannelHeader && (
              <>
                <div style={{display: 'block'}}>
                  <Text transform={channel.pathType === 'sms' ? 'uppercase' : 'capitalize'}>
                    {I18n.t('%{pathType}', {pathType: channel.pathType})}
                  </Text>
                </div>
                <div style={{display: 'block'}}>
                  <TruncateText>
                    <Text weight="light">{channel.path}</Text>
                  </TruncateText>
                </div>
              </>
            )}
          </Table.ColHeader>
        ))}
      </Table.Row>
    </Table.Head>
    <Table.Body>
      {Object.keys(notificationPreferences.channels[0].categories[notificationCategory])
        .filter(
          category =>
            notificationPreferences.channels[0].categories[notificationCategory][category]
              .notification
        )
        .map(category => (
          <Table.Row key={category} data-testid={formatCategoryKey(category)}>
            <Table.Cell>
              {
                notificationPreferences.channels[0].categories[notificationCategory][category]
                  .notification.categoryDisplayName
              }
            </Table.Cell>
            {notificationPreferences.channels.map(channel => (
              <Table.Cell textAlign="center" key={category + channel.path}>
                {channel.pathType === 'sms' &&
                ENV?.NOTIFICATION_PREFERENCES_OPTIONS?.deprecate_sms_enabled &&
                !ENV?.NOTIFICATION_PREFERENCES_OPTIONS?.allowed_sms_categories.includes(
                  formatCategoryKey(category)
                ) ? (
                  <Text>disabled</Text>
                ) : (
                  channel.categories[notificationCategory][category].frequency
                )}
              </Table.Cell>
            ))}
          </Table.Row>
        ))}
    </Table.Body>
  </Table>
)

const formatPreferencesData = preferences => {
  preferences.channels.forEach((channel, i) => {
    // copying the notificationCategories object defined above and setting it on each comms channel
    // so that we can update and mutate the object for each channel without it effecting the others
    preferences.channels[i].categories = JSON.parse(JSON.stringify(notificationCategories))
    setNotificationPolicy(channel.notificationPolicies, preferences.channels[i].categories)
    setNotificationPolicy(channel.notificationPolicyOverrides, preferences.channels[i].categories)
  })
}

const setNotificationPolicy = (policies, categories) => {
  if (!policies) return
  policies.forEach(np => {
    Object.keys(categories).forEach(key => {
      if (categories[key].hasOwnProperty(np.notification?.category)) {
        categories[key][np.notification.category] = np
      }
    })
  })
}

const NotificationPreferencesTable = props => {
  if (props.preferences.channels?.length > 0) {
    formatPreferencesData(props.preferences)
    return (
      <>
        {Object.keys(props.preferences.channels[0].categories).map((notificationCategory, i) =>
          renderNotificationCategory(props.preferences, notificationCategory, i === 0)
        )}
      </>
    )
  }
}

NotificationPreferencesTable.propTypes = {
  preferences: NotificationPreferencesShape
}

export default NotificationPreferencesTable
