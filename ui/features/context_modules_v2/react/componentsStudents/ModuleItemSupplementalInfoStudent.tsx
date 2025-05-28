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
import {ModuleItemContent, CompletionRequirement} from '../utils/types'
import CompletionRequirementDisplay from './CompletionRequirementDisplay'

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemSupplementalInfoStudentProps {
  contentTagId?: string
  content?: ModuleItemContent
  completionRequirement?: CompletionRequirement
}

const ModuleItemSupplementalInfoStudent: React.FC<ModuleItemSupplementalInfoStudentProps> = ({
  content,
  completionRequirement,
}) => {
  if (!content) return null

  const cachedDueDate = content.submissionsConnection?.nodes?.[0]?.cachedDueDate
  const hasDueDate = !!cachedDueDate
  const hasPointsPossible = content.pointsPossible !== undefined && content.pointsPossible !== null
  const hasCompletionRequirement = !!completionRequirement

  return (
    <Flex gap="xx-small" wrap="wrap" data-testid="module-item-supplemental-info">
      {hasDueDate && (
        <Flex.Item padding="0 0 0 small">
          <Text weight="normal" size="x-small">
            <FriendlyDatetime
              data-testid="due-date"
              prefix={I18n.t('Due: ')}
              format={I18n.t('#date.formats.date_at_time')}
              showTime={true}
              dateTime={cachedDueDate || null}
            />
          </Text>
        </Flex.Item>
      )}

      {hasPointsPossible && (
        <Flex.Item padding="0 0 0 small">
          <Text weight="normal" size="x-small">
            {I18n.t('%{points} pts', {points: content.pointsPossible})}
          </Text>
        </Flex.Item>
      )}

      {hasCompletionRequirement && (
        <CompletionRequirementDisplay completionRequirement={completionRequirement} />
      )}
    </Flex>
  )
}

export default ModuleItemSupplementalInfoStudent
