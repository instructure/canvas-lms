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

import React from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkpoint, ModuleItemContent} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

interface ModuleDiscussionCheckpointStudentProps {
  contentTagId?: string
  content?: ModuleItemContent
  checkpoints?: Checkpoint[]
  replyToEntryRequiredCount?: number
}

const ModuleDiscussionCheckpointStudent: React.FC<ModuleDiscussionCheckpointStudentProps> = ({
  content,
  checkpoints,
  replyToEntryRequiredCount,
}) => {
  if (!content || !checkpoints) return null

  const getCheckpointDescription = (checkpoint: Checkpoint) => {
    if (checkpoint.tag === 'reply_to_topic') {
      return I18n.t('Reply to Topic: ')
    } else if (checkpoint.tag === 'reply_to_entry') {
      if (replyToEntryRequiredCount && replyToEntryRequiredCount > 0) {
        return I18n.t('Required Replies (%{count}): ', {count: replyToEntryRequiredCount})
      }
      return I18n.t('Reply to Entry')
    }
    return checkpoint.name || ''
  }

  return (
    <Flex
      gap="xx-small"
      wrap="wrap"
      direction="row"
      data-testid="module-discussion-checkpoint"
      justifyItems="space-between"
      width="100%"
    >
      {checkpoints.map((checkpoint, index) => (
        <React.Fragment key={index}>
          <Flex.Item>
            <Text weight="bold" size="x-small">
              {getCheckpointDescription(checkpoint)}
            </Text>
            <Text weight="normal" size="x-small">
              <FriendlyDatetime
                data-testid="due-date"
                format={I18n.t('#date.formats.date_at_time')}
                showTime={true}
                dateTime={checkpoint.dueAt || null}
              />
            </Text>
          </Flex.Item>
          {index < checkpoints.length - 1 && (
            <Flex.Item padding="0">
              <Text>|</Text>
            </Flex.Item>
          )}
        </React.Fragment>
      ))}
    </Flex>
  )
}

export default ModuleDiscussionCheckpointStudent
