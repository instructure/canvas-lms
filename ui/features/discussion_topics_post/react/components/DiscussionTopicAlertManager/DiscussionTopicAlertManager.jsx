/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import DateHelper from '@canvas/datetime/dateHelper'
import {Discussion} from '../../../graphql/Discussion'
import {responsiveQuerySizes} from '../../utils'
import {useScope as useI18nScope} from '@canvas/i18n'

import React from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive/lib/Responsive'

const I18n = useI18nScope('discussion_posts')

export const DiscussionTopicAlertManager = props => {
  const getAnonymousAlertText = () => {
    const teacherFullAnonAlert = I18n.t(
      'This is an anonymous Discussion. Though student names and profile pictures will be hidden, your name and profile picture will be visible to all course members. Mentions have also been disabled.'
    )
    const studentFullAnonAlert = I18n.t(
      'This is an anonymous Discussion. Your name and profile picture will be hidden from other course members. Mentions have also been disabled.'
    )
    const observerFullAnonAlert = I18n.t(
      'This is an anonymous Discussion. Student names and profile pictures are hidden.'
    )
    const teacherPartialAnonAlert = I18n.t(
      'When creating a reply, students will have the option to show their name and profile picture or remain anonymous. Your name and profile picture will be visible to all course members. Mentions have also been disabled.'
    )
    const studentPartialAnonAlert = I18n.t(
      'When creating a reply, you will have the option to show your name and profile picture to other course members or remain anonymous. Mentions have also been disabled.'
    )
    const observerPartialAnonAlert = I18n.t(
      'Students have the option to reply anonymously. Some names and profile pictures may be hidden.'
    )
    const isObserver = ENV.current_user_roles?.includes('observer')

    if (props.discussionTopic.anonymousState === 'full_anonymity') {
      if (isObserver) return observerFullAnonAlert
      return props.discussionTopic.canReplyAnonymously ? studentFullAnonAlert : teacherFullAnonAlert
    } else {
      if (isObserver) return observerPartialAnonAlert
      return props.discussionTopic.canReplyAnonymously
        ? studentPartialAnonAlert
        : teacherPartialAnonAlert
    }
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          alert: {
            textSize: 'small',
          },
        },
        desktop: {
          alert: {
            textSize: 'medium',
          },
        },
      }}
      render={responsiveProps => {
        const applicableAlerts = []

        if (props.discussionTopic.initialPostRequiredForCurrentUser) {
          applicableAlerts.push(
            <Alert key="post-required" renderCloseButtonLabel="Close" margin="0 0 x-small">
              <Text data-testid="post-required" size={responsiveProps?.alert?.textSize}>
                {I18n.t(
                  'You must post before seeing replies. Edit history will be available to instructors.'
                )}
              </Text>
            </Alert>
          )
        }

        if (
          props.discussionTopic.permissions?.readAsAdmin &&
          props.discussionTopic.groupSet &&
          props.discussionTopic.assignment?.onlyVisibleToOverrides
        ) {
          applicableAlerts.push(
            <Alert
              key="differentiated-group-topics"
              renderCloseButtonLabel="Close"
              margin="0 0 x-small"
            >
              <Text
                data-testid="differentiated-group-topics"
                size={responsiveProps?.alert?.textSize}
              >
                {I18n.t(
                  'Note: for differentiated group topics, some threads may not have any students assigned.'
                )}
              </Text>
            </Alert>
          )
        }

        if (
          props.discussionTopic.isAnnouncement &&
          props.discussionTopic.delayedPostAt &&
          Date.parse(props.discussionTopic.delayedPostAt) > Date.now()
        ) {
          applicableAlerts.push(
            <Alert key="delayed-until" renderCloseButtonLabel="Close" margin="0 0 x-small">
              <Text data-testid="delayed-until" size={responsiveProps?.alert?.textSize}>
                {I18n.t('This announcement will not be visible until %{delayedPostAt}.', {
                  delayedPostAt: DateHelper.formatDatetimeForDiscussions(
                    props.discussionTopic.delayedPostAt
                  ),
                })}
              </Text>
            </Alert>
          )
        }

        if (!props.discussionTopic.availableForUser) {
          applicableAlerts.push(
            <Alert key="locked-for-user" renderCloseButtonLabel="Close" margin="0 0 x-small">
              <Text data-testid="locked-for-user" size={responsiveProps?.alert?.textSize}>
                {I18n.t('This topic will be available %{delayedPostAt}.', {
                  delayedPostAt: props.discussionTopic.assignment
                    ? DateHelper.formatDatetimeForDiscussions(
                        props.discussionTopic.assignment.unlockAt
                      )
                    : DateHelper.formatDatetimeForDiscussions(props.discussionTopic.delayedPostAt),
                })}
              </Text>
            </Alert>
          )
        }

        if (props.discussionTopic.anonymousState) {
          applicableAlerts.push(
            <Alert key="anon-conversation" variant="info" margin="0 0 x-small">
              <Text data-testid="anon-conversation" size={responsiveProps?.alert?.textSize}>
                {getAnonymousAlertText()}
              </Text>
            </Alert>
          )
        }
        return applicableAlerts
      }}
    />
  )
}

DiscussionTopicAlertManager.propTypes = {
  discussionTopic: Discussion.shape.isRequired,
}
