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

import React, {useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleHeaderStudent from './ModuleHeaderStudent'
import ModuleItemListStudent from './ModuleItemListStudent'
import {useModuleItemsStudent} from '../hooks/queriesStudent/useModuleItemsStudent'
import {
  CompletionRequirement,
  ModuleProgression,
  ModuleStatistics,
  Prerequisite,
} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')
export interface ModuleStudentProps {
  id: string
  name: string
  completionRequirements?: CompletionRequirement[]
  prerequisites?: Prerequisite[]
  expanded?: boolean
  onToggleExpand?: (id: string) => void
  requireSequentialProgress?: boolean
  progression?: ModuleProgression
  requirementCount?: number
  unlockAt: string | null
  submissionStatistics?: ModuleStatistics
}

const ModuleStudent: React.FC<ModuleStudentProps> = ({
  id,
  completionRequirements,
  prerequisites,
  expanded: propExpanded,
  onToggleExpand,
  name,
  requireSequentialProgress,
  progression,
  requirementCount,
  unlockAt,
  submissionStatistics,
}) => {
  const [isExpanded, setIsExpanded] = useState(propExpanded !== undefined ? propExpanded : false)
  const {data, isLoading, error} = useModuleItemsStudent(id, !!isExpanded)

  const toggleExpanded = (moduleId: string) => {
    const newExpandedState = !isExpanded
    setIsExpanded(newExpandedState)
    if (onToggleExpand) {
      onToggleExpand(moduleId)
    }
  }

  useEffect(() => {
    if (propExpanded !== undefined) {
      setIsExpanded(propExpanded)
    }
  }, [propExpanded])

  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: '1000px'},
      }}
      render={(_, matches) => {
        const smallScreen = !!matches?.includes('small')
        return (
          <View
            as="div"
            margin="0 0 large 0"
            padding="0"
            background="secondary"
            borderRadius="medium"
            shadow="resting"
            overflowX="hidden"
            data-module-id={id}
            className={`context_module module_${id}`}
            id={`context_module_${id}`}
          >
            <Flex direction="column">
              <Flex.Item>
                <ModuleHeaderStudent
                  id={id}
                  name={name}
                  expanded={isExpanded}
                  onToggleExpand={toggleExpanded}
                  progression={progression}
                  completionRequirements={completionRequirements}
                  prerequisites={prerequisites}
                  requirementCount={requirementCount}
                  unlockAt={unlockAt}
                  submissionStatistics={submissionStatistics}
                  smallScreen={smallScreen}
                />
              </Flex.Item>
              {isExpanded && (
                <Flex.Item>
                  <ModuleItemListStudent
                    moduleItems={data?.moduleItems || []}
                    requireSequentialProgress={requireSequentialProgress}
                    completionRequirements={completionRequirements}
                    progression={progression}
                    isLoading={isLoading}
                    error={error}
                    smallScreen={smallScreen}
                  />
                </Flex.Item>
              )}
            </Flex>
          </View>
        )
      }}
    />
  )
}

export default ModuleStudent
