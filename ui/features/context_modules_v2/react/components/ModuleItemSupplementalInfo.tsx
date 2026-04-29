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

import React, {useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {ModuleItemContent, CompletionRequirement, Checkpoint} from '../utils/types'
import CompletionRequirementDisplay from '../components/CompletionRequirementDisplay'
import DueDateLabel from './DueDateLabel'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemSupplementalInfoProps {
  contentTagId: string
  content: ModuleItemContent
  completionRequirement?: CompletionRequirement
}

const getCheckpointDescription = (checkpoint: Checkpoint, replyToEntryRequiredCount?: number) => {
  if (checkpoint.tag === 'reply_to_topic') {
    return I18n.t('Reply to Topic')
  } else if (checkpoint.tag === 'reply_to_entry') {
    if (replyToEntryRequiredCount && replyToEntryRequiredCount > 0) {
      return I18n.t('Required Replies (%{count})', {count: replyToEntryRequiredCount})
    }
    return I18n.t('Reply to Entry')
  }
  return checkpoint.name || I18n.t('Checkpoint')
}

const ModuleItemSupplementalInfo: React.FC<ModuleItemSupplementalInfoProps> = ({
  contentTagId,
  content,
  completionRequirement,
}) => {
  const sections = useMemo(() => {
    // Return empty array if no content
    if (!content) return []

    const sections: React.ReactNode[] = []

    // Handle checkpointed discussions
    if (content?.checkpoints && content.checkpoints.length > 0) {
      content.checkpoints.forEach((checkpoint, index) => {
        const checkpointContent = {
          ...checkpoint,
          type: 'Discussion' as const,
        }

        const hasAnyDueDate = checkpoint.assignedToDates?.some(date => date.dueAt)

        const dateComponent = hasAnyDueDate ? (
          <DueDateLabel content={checkpointContent} contentTagId={contentTagId} />
        ) : null

        if (dateComponent) {
          sections.push(
            <Flex.Item key={`checkpoint-${index}`}>
              <Text weight="bold" size="x-small">
                {getCheckpointDescription(checkpoint, content.replyToEntryRequiredCount)}:{' '}
              </Text>
              {dateComponent}
            </Flex.Item>,
          )
        } else if (checkpoint.assignedToDates && checkpoint.assignedToDates.length > 1) {
          // Has overrides but no dates - show "No Due Date"
          sections.push(
            <Flex.Item key={`checkpoint-${index}`}>
              <Text weight="bold" size="x-small">
                {getCheckpointDescription(checkpoint, content.replyToEntryRequiredCount)}:{' '}
              </Text>
              <Text weight="normal" size="x-small">
                No Due Date
              </Text>
            </Flex.Item>,
          )
        } else {
          // No overrides and no dates - show just the label
          sections.push(
            <Flex.Item key={`checkpoint-${index}`}>
              <Text weight="normal" size="x-small">
                {getCheckpointDescription(checkpoint, content.replyToEntryRequiredCount)}
              </Text>
            </Flex.Item>,
          )
        }
      })
    } else {
      // Handle regular content dates - only push if DueDateLabel would render something
      const hasStandardizedDates = content?.assignedToDates?.some(d => d.dueAt) ?? false

      if (hasStandardizedDates) {
        const dateComponent = <DueDateLabel content={content} contentTagId={contentTagId} />
        sections.push(<Flex.Item key="due-date">{dateComponent}</Flex.Item>)
      }
    }

    // Handle points possible
    if (content?.pointsPossible !== undefined && content?.pointsPossible !== null) {
      sections.push(
        <Flex.Item key="points">
          <Text weight="normal" size="x-small">
            {I18n.t('%{points} pts', {points: content.pointsPossible})}
          </Text>
        </Flex.Item>,
      )
    }

    // Handle completion requirement
    if (completionRequirement) {
      sections.push(
        <Flex.Item key="completion">
          <CompletionRequirementDisplay
            completionRequirement={completionRequirement}
            itemContent={content!}
          />
        </Flex.Item>,
      )
    }

    // Filter out null/undefined sections and empty React elements
    return sections.filter(section => {
      if (!section) return false
      // If it's a React element, check if it has meaningful content
      if (React.isValidElement(section)) {
        // For now, assume all valid React elements are meaningful
        return true
      }
      return Boolean(section)
    })
  }, [content, completionRequirement, contentTagId])

  // Don't render if no sections
  if (sections.length === 0) {
    return null
  }

  return (
    <Flex gap="xx-small" padding="x-small xx-small 0" wrap="wrap">
      {sections.map((section, index) => (
        <React.Fragment key={index}>
          {section}
          {index < sections.length - 1 && (
            <Flex.Item>
              <Text weight="normal" size="x-small" aria-hidden="true">
                |
              </Text>
            </Flex.Item>
          )}
        </React.Fragment>
      ))}
    </Flex>
  )
}

export default ModuleItemSupplementalInfo
