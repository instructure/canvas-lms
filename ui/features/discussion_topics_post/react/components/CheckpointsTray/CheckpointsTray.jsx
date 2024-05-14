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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import DateHelper from '@canvas/datetime/dateHelper'
import {IconDiscussionCheckLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Checkpoint} from '../../../graphql/Checkpoint'
import {Submission} from '../../../graphql/Submission'
import {REPLY_TO_TOPIC, REPLY_TO_ENTRY, SUBMITTED, MISSING, LATE} from '../../utils/constants'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export function CheckpointsTray({...props}) {
  const getCheckpointDueString = checkpointData => {
    return checkpointData?.dueAt
      ? I18n.t('Due: %{dueAt}', {
          dueAt: DateHelper.formatDatetimeForDiscussions(checkpointData.dueAt),
        })
      : I18n.t('Due: No Due Date')
  }
  const replyToTopicCheckpoint = props.checkpoints?.find(
    checkpoint => checkpoint.tag === REPLY_TO_TOPIC
  )
  const replyToEntryCheckpoint = props.checkpoints?.find(
    checkpoint => checkpoint.tag === REPLY_TO_ENTRY
  )

  const renderSubmissionStatus = (submission = {}) => {
    if (submission.submissionStatus === SUBMITTED) {
      return (
        <Flex.Item align="start">
          <Text size="small" color="success" weight="bold">
            <IconDiscussionCheckLine />
            &nbsp;
            {I18n.t('Completed %{submittedAt}', {
              submittedAt: DateHelper.formatDatetimeForDiscussions(submission.submittedAt),
            })}
          </Text>
        </Flex.Item>
      )
    } else if (submission.submissionStatus === LATE) {
      return (
        <Flex.Item align="start">
          <Text size="small" color="brand" weight="bold">
            {I18n.t('Late %{submittedAt}', {
              submittedAt: DateHelper.formatDatetimeForDiscussions(submission.submittedAt),
            })}
          </Text>
        </Flex.Item>
      )
    } else if (submission.submissionStatus === MISSING) {
      return (
        <Flex.Item align="start">
          <Text size="small" color="danger" weight="bold">
            {I18n.t('Missing')}
          </Text>
        </Flex.Item>
      )
    } else {
      // typically this means unsubmitted, and not late
      return null
    }
  }

  return (
    <Flex direction="column">
      {replyToTopicCheckpoint && (
        <Flex.Item data-testid="reply_to_topic_section">
          <View
            as="div"
            borderWidth={replyToEntryCheckpoint ? '0 0 small 0' : 'none'}
            padding="0 0 small 0"
          >
            <Flex direction="column">
              <Flex.Item align="start">
                <Text size="small">{I18n.t('Reply to Topic')} </Text>
              </Flex.Item>
              <Flex.Item align="start">
                <Text size="small">{getCheckpointDueString(replyToTopicCheckpoint)}</Text>
              </Flex.Item>
              {renderSubmissionStatus(props.replyToTopicSubmission)}
            </Flex>
          </View>
        </Flex.Item>
      )}{' '}
      {replyToEntryCheckpoint && (
        <Flex.Item data-testid="reply_to_entry_section" padding="small 0 0 0">
          <Flex direction="column">
            <Flex.Item align="start">
              <Text size="small">
                {I18n.t('Additional Replies Required: %{replyToEntryRequiredCount}', {
                  replyToEntryRequiredCount: props.replyToEntryRequiredCount,
                })}
              </Text>
            </Flex.Item>
            <Flex.Item align="start">
              <Text size="small">{getCheckpointDueString(replyToEntryCheckpoint)}</Text>
            </Flex.Item>
            {renderSubmissionStatus(props.replyToEntrySubmission)}
          </Flex>
        </Flex.Item>
      )}
    </Flex>
  )
}

CheckpointsTray.propTypes = {
  checkpoints: PropTypes.arrayOf(Checkpoint.shape),
  replyToEntryRequiredCount: PropTypes.number,
  replyToTopicSubmission: Submission.shape,
  replyToEntrySubmission: Submission.shape,
}
