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
import {Text} from '@instructure/ui-text'
import {Checkpoint} from '../../../graphql/Checkpoint'
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
  const replyToTopicData = props.checkpoints?.find(
    checkpoint => checkpoint.tag === 'reply_to_topic'
  )
  const replyToEntryData = props.checkpoints?.find(
    checkpoint => checkpoint.tag === 'reply_to_entry'
  )

  return (
    <Flex direction="column">
      {replyToTopicData && (
        <Flex.Item data-testid="reply_to_topic_section">
          <View
            as="div"
            borderWidth={replyToEntryData ? '0 0 small 0' : 'none'}
            padding="0 0 small 0"
          >
            <Flex direction="column">
              <Flex.Item align="start">
                <Text size="small">{I18n.t('Reply to Topic')} </Text>
              </Flex.Item>
              <Flex.Item align="start">
                <Text size="small">{getCheckpointDueString(replyToTopicData)}</Text>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
      )}{' '}
      {replyToEntryData && (
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
              <Text size="small">{getCheckpointDueString(replyToEntryData)}</Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      )}
    </Flex>
  )
}

CheckpointsTray.propTypes = {
  checkpoints: PropTypes.arrayOf(Checkpoint.shape),
  replyToEntryRequiredCount: PropTypes.number,
}
