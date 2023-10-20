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
import {func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import NotificationPreferencesSetting from './Setting'
import {NotificationPreferencesShape} from './Shape'
import React, {useEffect, useState} from 'react'

import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('notification_preferences')

const formattedCategoryNames = {
  courseActivities: () => I18n.t('Course Activities'),
  discussions: () => I18n.t('Discussions'),
  conversations: () => I18n.t('Conversations'),
  scheduling: () => I18n.t('Scheduling'),
  groups: () => I18n.t('Groups'),
  conferences: () => I18n.t('Conferences'),
  alerts: () => I18n.t('Alerts'),
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
    Blueprint: {},
  },
  discussions: {
    Discussion: {},
    DiscussionEntry: {},
    DiscussionMention: {},
  },
  conversations: {
    'Added To Conversation': {},
    'Conversation Message': {},
    'Conversation Created': {},
  },
  scheduling: {
    'Student Appointment Signups': {},
    'Appointment Signups': {},
    'Appointment Cancelations': {},
    'Appointment Availability': {},
    Calendar: {},
  },
  groups: {
    'Membership Update': {},
  },
  conferences: {
    'Recording Ready': {},
  },
  alerts: {
    Other: {},
    'Content Link Error': {},
    'Account Notification': {},
  },
}

const formatCategoryKey = category => {
  let categoryStrings = category.split(/(?=[A-Z])/)
  categoryStrings = categoryStrings.map(word => word[0].toLowerCase() + word.slice(1))
  return categoryStrings.join('_').replace(/\s/g, '')
}

const pushNotificationCategoryRestricted = category => {
  return !ENV?.NOTIFICATION_PREFERENCES_OPTIONS?.allowed_push_categories.includes(category)
}

const menuShouldBeDisabled = (category, pathType) => {
  if (pathType === 'sms') return true
  else if (pathType === 'push') return pushNotificationCategoryRestricted(category)
  else return false
}

const renderNotificationCategory = (
  notificationPreferences,
  notificationCategory,
  updatePreferenceCallback,
  renderChannelHeader,
  sendScoresInEmails,
  setSendScoresInEmails
) => (
  <React.Fragment key={notificationCategory}>
    {!(notificationCategory === 'conversations' && ENV.current_user_disabled_inbox) && (
      <Table
        caption={I18n.t('%{categoryName} notification preferences', {
          categoryName: formattedCategoryNames[notificationCategory](),
        })}
        margin="medium 0"
        layout="fixed"
      >
        <Table.Head>
          <Table.Row>
            <Table.ColHeader
              id={notificationCategory}
              data-testid={notificationCategory}
              width="16rem"
            >
              <Text size="large">{formattedCategoryNames[notificationCategory]()}</Text>
            </Table.ColHeader>
            {notificationPreferences.channels.map(channel => (
              <Table.ColHeader
                textAlign="center"
                id={`${notificationCategory}-${channel.path}`}
                key={`${notificationCategory}-${channel.path}`}
                width="8rem"
              >
                {renderChannelHeader ? (
                  <>
                    <div style={{display: 'block'}}>
                      {channel.pathType === 'push' ? (
                        <Text>{I18n.t('Push Notification')}</Text>
                      ) : (
                        <Text transform={channel.pathType === 'sms' ? 'uppercase' : 'capitalize'}>
                          {channel.pathType}
                        </Text>
                      )}
                    </div>
                    <div style={{display: 'block'}}>
                      <TruncateText>
                        <Text weight="light">
                          {channel.pathType === 'push' ? I18n.t('For All Devices') : channel.path}
                        </Text>
                      </TruncateText>
                    </div>
                  </>
                ) : (
                  <ScreenReaderContent>
                    {channel.pathType}
                    {channel.path}
                  </ScreenReaderContent>
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
                <Table.RowHeader>
                  <Tooltip
                    renderTip={
                      <div
                        dangerouslySetInnerHTML={{
                          __html:
                            notificationPreferences.channels[0].categories[notificationCategory][
                              category
                            ].notification.categoryDescription,
                        }}
                        data-testid={`${formatCategoryKey(category)}_description`}
                      />
                    }
                    placement="end"
                  >
                    <span
                      // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                      tabIndex="0"
                      style={{padding: theme.variables.spacing.xxSmall}}
                      data-testid={`${formatCategoryKey(category)}_header`}
                    >
                      {
                        notificationPreferences.channels[0].categories[notificationCategory][
                          category
                        ].notification.categoryDisplayName
                      }
                    </span>
                  </Tooltip>
                  <ScreenReaderContent>
                    <div
                      dangerouslySetInnerHTML={{
                        __html:
                          notificationPreferences.channels[0].categories[notificationCategory][
                            category
                          ].notification.categoryDescription,
                      }}
                      data-testid={`${formatCategoryKey(category)}_screenReader`}
                    />
                  </ScreenReaderContent>
                  {category === 'Grading' &&
                    renderSendScoresInEmailsToggle(
                      sendScoresInEmails,
                      setSendScoresInEmails,
                      updatePreferenceCallback
                    )}
                </Table.RowHeader>
                {notificationPreferences.channels.map(channel => (
                  <Table.Cell textAlign="center" key={category + channel.path}>
                    <NotificationPreferencesSetting
                      selectedPreference={
                        menuShouldBeDisabled(formatCategoryKey(category), channel.pathType)
                          ? 'disabled'
                          : channel.categories[notificationCategory][category].frequency
                      }
                      preferenceOptions={
                        channel.pathType === 'email'
                          ? ['immediately', 'daily', 'weekly', 'never']
                          : ['immediately', 'never']
                      }
                      updatePreference={frequency =>
                        updatePreferenceCallback({channel, category, frequency})
                      }
                    />
                  </Table.Cell>
                ))}
              </Table.Row>
            ))}
        </Table.Body>
      </Table>
    )}
  </React.Fragment>
)

const renderSendScoresInEmailsToggle = (
  sendScoresInEmails,
  setSendScoresInEmails,
  updatePreferenceCallback
) => {
  if (ENV.NOTIFICATION_PREFERENCES_OPTIONS.send_scores_in_emails_text !== null) {
    return (
      <View margin="x-small 0 0 small" display="block">
        <Checkbox
          data-testid="grading-send-score-in-email"
          label={ENV.NOTIFICATION_PREFERENCES_OPTIONS.send_scores_in_emails_text.label}
          size="small"
          variant="toggle"
          checked={sendScoresInEmails}
          onChange={() => {
            // this reflects the change faster than waiting to the prop be updated by updatePreferenceCallback
            setSendScoresInEmails(!sendScoresInEmails)
            updatePreferenceCallback({sendScoresInEmails: !sendScoresInEmails})
          }}
        />
      </View>
    )
  }
}

const formatPreferencesData = preferences => {
  preferences.channels.forEach((channel, i) => {
    // copying the notificationCategories object defined above and setting it on each comms channel
    // so that we can update and mutate the object for each channel without it effecting the others.
    // We are also using the structure defined above because we care about the order that the
    // preferences are displayed in.
    preferences.channels[i].categories = JSON.parse(JSON.stringify(notificationCategories))
    setNotificationPolicy(channel.notificationPolicies, preferences.channels[i].categories)
    setNotificationPolicy(channel.notificationPolicyOverrides, preferences.channels[i].categories)
    dropEmptyCategories(preferences.channels[i].categories)
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

const dropEmptyCategories = categories => {
  Object.keys(categories).forEach(categoryGroup => {
    Object.keys(categories[categoryGroup]).forEach(category => {
      if (Object.keys(categories[categoryGroup][category]).length === 0) {
        delete categories[categoryGroup][category]
      }
    })
    if (Object.keys(categories[categoryGroup]).length === 0) {
      delete categories[categoryGroup]
    }
  })
}

const NotificationPreferencesTable = props => {
  const {sendScoresInEmails} = props.preferences
  const [stageSendScoresInEmails, setStageSendScoresInEmails] = useState(
    props.preferences.sendScoresInEmails
  )

  useEffect(() => {
    setStageSendScoresInEmails(sendScoresInEmails)
  }, [sendScoresInEmails])

  if (ENV.discussions_reporting && ENV?.current_user_roles?.includes('teacher')) {
    notificationCategories.discussions.ReportedReply = {}
  }

  if (props.preferences.channels?.length > 0) {
    formatPreferencesData(props.preferences)
    return (
      <>
        {Object.keys(props.preferences.channels[0].categories).map((notificationCategory, i) =>
          renderNotificationCategory(
            props.preferences,
            notificationCategory,
            props.updatePreference,
            i === 0,
            stageSendScoresInEmails,
            setStageSendScoresInEmails
          )
        )}
      </>
    )
  }
  return null
}

NotificationPreferencesTable.propTypes = {
  preferences: NotificationPreferencesShape,
  updatePreference: func.isRequired,
}

export default NotificationPreferencesTable
