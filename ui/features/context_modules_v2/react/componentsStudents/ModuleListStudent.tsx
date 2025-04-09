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

import React, {useState, useEffect, useCallback, useRef} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import ModuleStudent from './ModuleStudent'
import ModulePageActionHeaderStudent from './ModulePageActionHeaderStudent'
import {
  handleCollapseAll,
  handleExpandAll,
  handleToggleExpand,
} from '../handlers/modulePageActionHandlers'

import {useModules} from '../hooks/queries/useModules'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

const ModulesListStudent: React.FC = () => {
  const {courseId} = useContextModule()
  const {data, isLoading, error, isFetchingNextPage, hasNextPage} = useModules(courseId)

  // Initialize with an empty Map - all modules will be collapsed by default
  const [expandedModules, setExpandedModules] = useState<Map<string, boolean>>(new Map())

  // Set initial expanded state for modules when data is loaded
  useEffect(() => {
    if (data?.pages) {
      const allModules = data.pages.flatMap(page => page.modules)

      // Create a Map with all modules collapsed by default
      const initialExpandedState = new Map<string, boolean>()
      allModules.forEach((module, index) => {
        // Expand the first 10 modules by default
        initialExpandedState.set(module._id, index < 10)
      })

      setExpandedModules(prev => {
        if (prev.size > 0) {
          const newState = new Map(prev)
          allModules.forEach((module, index) => {
            if (!newState.has(module._id)) {
              newState.set(module._id, index < 10)
            }
          })
          return newState
        }
        return initialExpandedState
      })
    }
  }, [data?.pages])

  const handleToggleExpandRef = useCallback((moduleId: string) => {
    handleToggleExpand(moduleId, setExpandedModules)
  }, [setExpandedModules])

  return (
      <View as="div" margin="medium">
        <ModulePageActionHeaderStudent
          onCollapseAll={() => handleCollapseAll(data, setExpandedModules)}
          onExpandAll={() => handleExpandAll(data, setExpandedModules)}
          anyModuleExpanded={Array.from(expandedModules.values()).some(expanded => expanded)}
        />
        {isLoading && !data ? (
          <View as="div" textAlign="center" padding="large">
            <Spinner renderTitle={I18n.t('Loading modules')} size="large" />
          </View>
        ) : error ? (
          <View as="div" textAlign="center" padding="large">
            <Text color="danger">{I18n.t('Error loading modules')}</Text>
          </View>
        ) : (
            <Flex direction="column" gap="small">
            {data?.pages[0]?.modules.length === 0 ? (
                <View as="div" textAlign="center" padding="large">
                  <Text>{I18n.t('No modules found')}</Text>
                </View>
              ) : (
                data?.pages.flatMap(page => page.modules).map((module) => (
                      <ModuleStudent
                        key={module._id}
                        id={module._id}
                        name={module.name}
                        completionRequirements={module.completionRequirements}
                        expanded={!!expandedModules.get(module._id)}
                        onToggleExpand={handleToggleExpandRef}
                      />
                  )))}
            </Flex>
          )
        }
        {hasNextPage && (
          <View as="div" padding="medium" textAlign="center">
            {isFetchingNextPage && (
              <Spinner renderTitle={I18n.t('Loading more modules')} size="small" margin="small" />
            )}
          </View>
        )}
      </View>
    )
  }


export default ModulesListStudent
