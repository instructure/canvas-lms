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
import {View} from '@instructure/ui-view'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleItemContent, CompletionRequirement, Checkpoint} from '../utils/types'
import CompletionRequirementDisplay from '../components/CompletionRequirementDisplay'
import ModuleDiscussionCheckpointStudent from './ModuleDiscussionCheckpointStudent'
import {useContextModule} from '../hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemSupplementalInfoStudentProps {
  contentTagId?: string
  content?: ModuleItemContent
  completionRequirement?: CompletionRequirement
  itemIcon?: React.ReactNode
  itemTypeText?: string
  checkpoints?: Checkpoint[]
  replyToEntryRequiredCount?: number
}

const ModuleItemSupplementalInfoStudent: React.FC<ModuleItemSupplementalInfoStudentProps> = ({
  contentTagId,
  content,
  completionRequirement,
  itemIcon,
  itemTypeText,
  checkpoints,
  replyToEntryRequiredCount,
}) => {
  const {restrictQuantitativeData} = useContextModule()

  if (!content) return null

  const cachedDueDate = content.submissionsConnection?.nodes?.[0]?.cachedDueDate
  const todoDate = content.todoDate
  const isUngradedDiscussion = content.type === 'Discussion' && content.graded === false
  const hasDueDate = !!cachedDueDate
  const hasTodoDate = !!todoDate && isUngradedDiscussion
  const hasPointsPossible =
    content.pointsPossible !== undefined &&
    content.pointsPossible !== null &&
    !restrictQuantitativeData
  const hasCompletionRequirement = !!completionRequirement

  return (
    <Flex wrap="wrap" data-testid="module-item-supplemental-info" padding="0 0 0 xx-small">
      {itemIcon && (
        <>
          <Flex.Item margin="0 small 0 0" aria-hidden="true">
            <View as="div">{itemIcon}</View>
          </Flex.Item>
          <Flex.Item margin="0">
            <Text size="x-small" transform="capitalize">
              {itemTypeText}
            </Text>
          </Flex.Item>
        </>
      )}

      {checkpoints && checkpoints.length > 0 ? (
        <>
          <Flex.Item padding="0 x-small">
            <Text size="x-small" aria-hidden="true">
              |
            </Text>
          </Flex.Item>
          <Flex.Item>
            <ModuleDiscussionCheckpointStudent
              contentTagId={contentTagId}
              content={content}
              checkpoints={checkpoints}
              replyToEntryRequiredCount={replyToEntryRequiredCount}
            />
          </Flex.Item>
        </>
      ) : (
        (hasDueDate || hasTodoDate) && (
          <>
            <Flex.Item padding="0 x-small">
              <Text size="x-small" aria-hidden="true">
                |
              </Text>
            </Flex.Item>
            <Flex.Item padding="0">
              <Text weight="bold" size="x-small">
                {I18n.t('Due: ')}
              </Text>
              <Text weight="normal" size="x-small">
                <FriendlyDatetime
                  data-testid={hasTodoDate ? 'todo-date' : 'due-date'}
                  format={I18n.t('#date.formats.date_at_time')}
                  showTime={true}
                  dateTime={(hasTodoDate ? todoDate : cachedDueDate) || null}
                  alwaysUseSpecifiedFormat={true}
                />
              </Text>
            </Flex.Item>
          </>
        )
      )}

      {hasPointsPossible && (
        <>
          <Flex.Item padding="0 x-small">
            <Text size="x-small" aria-hidden="true">
              |
            </Text>
          </Flex.Item>
          <Flex.Item padding="0">
            <Text weight="normal" size="x-small">
              {I18n.t('%{points} pts', {points: content.pointsPossible})}
            </Text>
          </Flex.Item>
        </>
      )}

      {hasCompletionRequirement && (
        <>
          <Flex.Item padding="0 x-small">
            <Text size="x-small" aria-hidden="true">
              |
            </Text>
          </Flex.Item>
          <CompletionRequirementDisplay
            completionRequirement={completionRequirement}
            itemContent={content}
          />
        </>
      )}
    </Flex>
  )
}

export default ModuleItemSupplementalInfoStudent
