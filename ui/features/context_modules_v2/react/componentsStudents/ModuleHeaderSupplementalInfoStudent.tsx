/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {CompletionRequirement, ModuleStatistics} from '../utils/types.d'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = createI18nScope('context_modules_v2')

type Props = {
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  submissionStatistics?: ModuleStatistics
  moduleCompleted?: boolean
}

export const ModuleHeaderSupplementalInfoStudent: React.FC<Props> = ({
  completionRequirements = [],
  requirementCount,
  submissionStatistics,
  moduleCompleted,
}) => {
  const dueDate = submissionStatistics?.latestDueAt
    ? new Date(submissionStatistics.latestDueAt)
    : null
  const missingCount = submissionStatistics?.missingAssignmentCount || 0

  const hasCompletionRequirements = completionRequirements && completionRequirements.length > 0

  const showMissingCount = missingCount > 0 && (!moduleCompleted || !hasCompletionRequirements)

  return (
    <View as="div" margin="0 0 0">
      <Flex wrap="wrap">
        <Flex.Item>
          {dueDate && (
            <Text size="x-small">
              <FriendlyDatetime
                prefix={I18n.t('Due: ')}
                format={I18n.t('#date.formats.short')}
                dateTime={dueDate}
              />
            </Text>
          )}
          {dueDate && (showMissingCount || hasCompletionRequirements) && (
            <Text size="x-small"> | </Text>
          )}
          {showMissingCount && (
            <Text size="x-small" color="danger">
              {I18n.t(
                {
                  one: '1 Missing Assignment',
                  other: '%{count} Missing Assignments',
                },
                {
                  count: missingCount,
                },
              )}
            </Text>
          )}
          {showMissingCount && hasCompletionRequirements && <Text size="x-small"> | </Text>}
          {hasCompletionRequirements && (
            <Text size="x-small">
              {`Requirement: ${requirementCount ? I18n.t('Complete One Item') : I18n.t('Complete All Items')}`}
            </Text>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}
