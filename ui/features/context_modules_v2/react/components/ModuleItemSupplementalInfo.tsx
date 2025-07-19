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

import React, {useMemo, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {ModuleItemContent, CompletionRequirement, Checkpoint} from '../utils/types'
import CompletionRequirementDisplay from '../components/CompletionRequirementDisplay'
import DueDateLabel from './DueDateLabel'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemSupplementalInfoProps {
  contentTagId: string
  content: ModuleItemContent
  completionRequirement?: CompletionRequirement
}

const ModuleItemSupplementalInfo: React.FC<ModuleItemSupplementalInfoProps> = ({
  contentTagId,
  content,
  completionRequirement,
}) => {
  const hasDueOrLockDate = useMemo(
    () =>
      content?.dueAt ||
      content?.lockAt ||
      content?.assignmentOverrides?.edges.some(({node}) => node.dueAt),
    [content?.dueAt, content?.lockAt, content?.assignmentOverrides?.edges],
  )

  const hasPointsPossible = useMemo(
    () => content?.pointsPossible !== undefined && content?.pointsPossible !== null,
    [content?.pointsPossible],
  )

  const hasCompletionRequirement = useMemo(() => !!completionRequirement, [completionRequirement])

  const hasCheckpoints = useMemo(
    () => content?.checkpoints && content.checkpoints.length > 0,
    [content?.checkpoints],
  )

  const getCheckpointDescription = useCallback(
    (checkpoint: Checkpoint) => {
      const hasDate = !!checkpoint.dueAt

      if (checkpoint.tag === 'reply_to_topic') {
        return hasDate ? I18n.t('Reply to Topic: ') : I18n.t('Reply to Topic')
      } else if (checkpoint.tag === 'reply_to_entry') {
        if (content?.replyToEntryRequiredCount && content.replyToEntryRequiredCount > 0) {
          return hasDate
            ? I18n.t('Required Replies (%{count}): ', {count: content.replyToEntryRequiredCount})
            : I18n.t('Required Replies (%{count})', {count: content.replyToEntryRequiredCount})
        }
        return hasDate ? I18n.t('Reply to Entry: ') : I18n.t('Reply to Entry')
      }
      return checkpoint.name ? (hasDate ? `${checkpoint.name}: ` : checkpoint.name) : ''
    },
    [content?.replyToEntryRequiredCount],
  )

  const checkpointElements = useMemo(() => {
    if (!hasCheckpoints || !content?.checkpoints) return null

    return content.checkpoints.map((checkpoint, index) => (
      <React.Fragment key={index}>
        <Flex.Item>
          <Text weight="normal" size="x-small">
            {getCheckpointDescription(checkpoint)}
            <FriendlyDatetime
              data-testid="checkpoint-due-date"
              format={I18n.t('#date.formats.medium')}
              dateTime={checkpoint.dueAt || null}
            />
          </Text>
        </Flex.Item>
        {content.checkpoints && index < content.checkpoints.length - 1 && (
          <Flex.Item>
            <Text weight="normal" size="x-small" aria-hidden="true">
              |
            </Text>
          </Flex.Item>
        )}
      </React.Fragment>
    ))
  }, [hasCheckpoints, content?.checkpoints, getCheckpointDescription])

  if (
    !content ||
    (!hasDueOrLockDate && !hasPointsPossible && !hasCompletionRequirement && !hasCheckpoints)
  )
    return null

  const renderCompletionRequirement = () => {
    if (!completionRequirement) return null

    return (
      <CompletionRequirementDisplay
        completionRequirement={completionRequirement}
        itemContent={content!}
      />
    )
  }

  return (
    <Flex gap="xx-small" padding="0 0 0 xx-small">
      {hasCheckpoints ? (
        <>
          {checkpointElements}
          {(hasPointsPossible || hasCompletionRequirement) && (
            <Flex.Item>
              <Text weight="normal" size="x-small" aria-hidden="true">
                |
              </Text>
            </Flex.Item>
          )}
        </>
      ) : (
        <>
          <DueDateLabel content={content!} contentTagId={contentTagId} />
          {hasDueOrLockDate && (hasPointsPossible || hasCompletionRequirement) && (
            <Flex.Item>
              <Text weight="normal" size="x-small" aria-hidden="true">
                |
              </Text>
            </Flex.Item>
          )}
        </>
      )}

      {hasPointsPossible && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            {I18n.t('%{points} pts', {points: content!.pointsPossible})}
          </Text>
        </Flex.Item>
      )}

      {hasPointsPossible && hasCompletionRequirement && (
        <Flex.Item>
          <Text weight="normal" size="x-small" aria-hidden="true">
            |
          </Text>
        </Flex.Item>
      )}

      {renderCompletionRequirement()}
    </Flex>
  )
}

export default ModuleItemSupplementalInfo
