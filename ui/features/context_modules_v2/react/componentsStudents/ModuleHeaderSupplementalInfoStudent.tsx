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

import React, {useMemo} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {CompletionRequirement, ModuleProgression} from '../utils/types.d'
import {useModuleItemsStudent} from '../hooks/queriesStudent/useModuleItemsStudent'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

type Props = {
  moduleId: string
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  progression?: ModuleProgression
}

export const ModuleHeaderSupplementalInfoStudent: React.FC<Props> = ({
  moduleId,
  completionRequirements = [],
  requirementCount,
  progression,
}) => {
  const {data: moduleItemData} = useModuleItemsStudent(moduleId)
  const {dueDate, overdueCount} = useMemo(() => {
    const availableDueDates = moduleItemData?.moduleItems?.filter(
      item => item?.content?.submissionsConnection?.nodes?.[0]?.cachedDueDate,
    )
    const dueDate = availableDueDates?.reduce((max, item) => {
      const dueDate = item?.content?.submissionsConnection?.nodes?.[0]?.cachedDueDate
      return dueDate ? new Date(dueDate) : max
    }, new Date(0))
    const overdueCount =
      moduleItemData?.moduleItems?.filter(
        item =>
          item?.content?.submissionsConnection?.nodes?.[0]?.cachedDueDate &&
          new Date(item?.content?.submissionsConnection?.nodes?.[0]?.cachedDueDate) < new Date() &&
          !progression?.requirementsMet?.some(req => req.id === item?._id),
      ).length || 0
    return {dueDate, overdueCount}
  }, [moduleItemData, progression])

  // Ensure we only proceed if completionRequirements exists
  const hasCompletionRequirements = completionRequirements && completionRequirements.length > 0

  return (
    <View as="div" margin="0 0 0">
      <Flex wrap="wrap">
        <Flex.Item>
          {dueDate && dueDate.getTime() > 0 && (
            <Text size="x-small">Due: {dueDate.toDateString()}</Text>
          )}
          {dueDate && dueDate.getTime() > 0 && (overdueCount || hasCompletionRequirements) && (
            <Text size="x-small"> | </Text>
          )}
          {overdueCount > 0 && (
            <Text size="x-small" color="danger">
              {overdueCount} Overdue Assignment
            </Text>
          )}
          {overdueCount > 0 && hasCompletionRequirements && <Text size="x-small"> | </Text>}
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
