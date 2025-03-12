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
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {ModuleContent, CompletionRequirement} from '../utils/types'
import CompletionRequirementInfo from '../components/CompletionRequirementInfo'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemSupplementalInfoProps {
  contentTagId: string
  content: ModuleContent
  completionRequirement?: CompletionRequirement
}

const ModuleItemSupplementalInfo: React.FC<ModuleItemSupplementalInfoProps> = ({content, completionRequirement}) => {
  if (!content) return null

  const hasDueOrLockDate = content.dueAt || content.lockAt
  const hasPointsPossible = content.pointsPossible !== undefined && content.pointsPossible !== null
  const hasCompletionRequirement = !!completionRequirement

  if (!hasDueOrLockDate && !hasPointsPossible && !hasCompletionRequirement) return null

  const renderCompletionRequirement = () => {
    if (!completionRequirement) return null

    const {type, minScore, minPercentage, completed = false} = completionRequirement
    const fulfillmentStatus = completed ? 'fulfilled' : 'unfulfilled'

    return <CompletionRequirementInfo
      type={type}
      minScore={minScore}
      minPercentage={minPercentage}
      completed={completed}
      fulfillmentStatus={fulfillmentStatus}
      id={content.id || ''}
    />
  }

  return (
    <Flex gap="xx-small">
      {hasDueOrLockDate && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            <FriendlyDatetime
              data-testid="due-date"
              format={I18n.t('#date.formats.medium')}
              dateTime={content.dueAt || content.lockAt || null}
            />
          </Text>
        </Flex.Item>
      )}

      {hasDueOrLockDate && (hasPointsPossible || hasCompletionRequirement) && (
        <Flex.Item>
          <Text weight="normal" size="x-small">|</Text>
        </Flex.Item>
      )}

      {hasPointsPossible && (
        <Flex.Item>
          <Text weight="normal" size="x-small">
            {I18n.t("%{points} pts", { points: content.pointsPossible })}
          </Text>
        </Flex.Item>
      )}

      {hasPointsPossible && hasCompletionRequirement && (
        <Flex.Item>
          <Text weight="normal" size="x-small">|</Text>
        </Flex.Item>
      )}

      {renderCompletionRequirement()}
    </Flex>
  )
}

export default ModuleItemSupplementalInfo
