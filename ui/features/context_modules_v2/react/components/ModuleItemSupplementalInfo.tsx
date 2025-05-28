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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {ModuleItemContent, CompletionRequirement} from '../utils/types'
import CompletionRequirementInfo from '../components/CompletionRequirementInfo'
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
  if (!content) return null

  const hasDueOrLockDate =
    content.dueAt ||
    content.lockAt ||
    content.assignmentOverrides?.edges.some(({node}) => node.dueAt)
  const hasPointsPossible = content.pointsPossible !== undefined && content.pointsPossible !== null
  const hasCompletionRequirement = !!completionRequirement

  if (!hasDueOrLockDate && !hasPointsPossible && !hasCompletionRequirement) return null

  const renderCompletionRequirement = () => {
    if (!completionRequirement) return null

    const {type, minScore, minPercentage, completed = false} = completionRequirement

    return (
      <CompletionRequirementInfo
        type={type}
        minScore={minScore}
        minPercentage={minPercentage}
        completed={completed}
        id={content.id || ''}
      />
    )
  }

  return (
    <Flex gap="xx-small">
      <DueDateLabel content={content} contentTagId={contentTagId} />

      {hasDueOrLockDate && (hasPointsPossible || hasCompletionRequirement) && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            |
          </Text>
        </Flex.Item>
      )}

      {hasPointsPossible && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            {I18n.t('%{points} pts', {points: content.pointsPossible})}
          </Text>
        </Flex.Item>
      )}

      {hasPointsPossible && hasCompletionRequirement && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            |
          </Text>
        </Flex.Item>
      )}

      {renderCompletionRequirement()}
    </Flex>
  )
}

export default ModuleItemSupplementalInfo
