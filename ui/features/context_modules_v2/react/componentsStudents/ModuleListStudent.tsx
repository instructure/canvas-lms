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

import React, {useState, useEffect, useCallback, memo} from 'react'
import {debounce} from '@instructure/debounce'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import ModuleStudent from './ModuleStudent'
import ModulePageActionHeaderStudent from './ModulePageActionHeaderStudent'
import {handleCollapseAll, handleExpandAll} from '../handlers/modulePageActionHandlers'
import {useIsFetching} from '@tanstack/react-query'

import {validateModuleStudentRenderRequirements} from '../utils/utils'
import {useModulesStudent} from '../hooks/queriesStudent/useModulesStudent'
import {useToggleCollapse, useToggleAllCollapse} from '../hooks/mutations/useToggleCollapse'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

const MemoizedModuleStudent = memo(ModuleStudent, validateModuleStudentRenderRequirements)

const ModulesListStudent: React.FC = () => {
  const {courseId} = useContextModule()
  const {data, isLoading, error, isFetchingNextPage, hasNextPage} = useModulesStudent(courseId)
  const moduleFetchingCount = useIsFetching({queryKey: ['moduleItemsStudent']})
  const [expandCollapseButtonDisabled, setExpandCollapseButtonDisabled] = useState(false)

  // Initialize with an empty Map - all modules will be collapsed by default
  const [expandedModules, setExpandedModules] = useState<Map<string, boolean>>(new Map())

  const toggleAllCollapse = useToggleAllCollapse(courseId)

  // Set initial expanded state for modules when data is loaded
  useEffect(() => {
    if (data?.pages) {
      const allModules = data.pages.flatMap(page => page.modules)

      // Create a Map for module expansion state
      const initialExpandedState = new Map<string, boolean>()
      allModules.forEach(module => {
        // Use collapsed state from progression if available
        if (module.progression && module.progression?.collapsed !== null) {
          // Note: we invert collapsed to get expanded state
          initialExpandedState.set(module._id, !module.progression.collapsed)
        } else {
          // Default all modules to collapsed
          initialExpandedState.set(module._id, false)
        }
      })

      setExpandedModules(prev => {
        if (prev.size > 0) {
          const newState = new Map(prev)
          allModules.forEach(module => {
            if (!newState.has(module._id)) {
              // For newly added modules, respect their progression collapsed state
              if (module.progression && module.progression.collapsed !== null) {
                newState.set(module._id, !module.progression.collapsed)
              } else {
                newState.set(module._id, false) // Default to collapsed
              }
            }
          })
          return newState
        }
        return initialExpandedState
      })
    }
  }, [data?.pages])

  useEffect(() => {
    if (moduleFetchingCount > 0) {
      setExpandCollapseButtonDisabled(true)
    } else {
      setExpandCollapseButtonDisabled(false)
    }
  }, [moduleFetchingCount])

  const toggleCollapseMutation = useToggleCollapse(courseId)

  const debouncedToggleCollapse = useCallback(() => {
    const debouncedFn = debounce((params: {moduleId: string; collapse: boolean}) => {
      toggleCollapseMutation.mutate(params)
    }, 500)

    return debouncedFn
  }, [toggleCollapseMutation])() // Execute immediately to get the debounced function

  const handleToggleAllCollapse = useCallback(
    (collapse: boolean) => {
      // Set the button disabled state immediately
      setExpandCollapseButtonDisabled(true)

      toggleAllCollapse.mutate(collapse, {
        onSettled: () => {
          // Reset disabled state when complete, whether success or error
          setExpandCollapseButtonDisabled(false)
        },
      })
    },
    [toggleAllCollapse, setExpandCollapseButtonDisabled],
  )

  // Clean up debounced functions on unmount
  useEffect(() => {
    return () => {
      // Cancel any pending debounced calls
      debouncedToggleCollapse.cancel()
    }
  }, [debouncedToggleCollapse])

  const handleToggleExpandRef = useCallback(
    (moduleId: string) => {
      const currentExpanded = expandedModules.get(moduleId) || false

      // Update UI immediately for responsiveness
      setExpandedModules(prev => {
        const newState = new Map(prev)
        newState.set(moduleId, !currentExpanded)
        return newState
      })

      // Debounce the API call to persist the collapsed state
      // Note: the endpoint expects 'collapse' which is the opposite of 'expanded'
      debouncedToggleCollapse({
        moduleId,
        collapse: currentExpanded, // If currently expanded, we're collapsing it
      })
    },
    [expandedModules, debouncedToggleCollapse],
  )

  return (
    <View as="div" margin="medium">
      <ModulePageActionHeaderStudent
        onCollapseAll={() => {
          // Update UI immediately
          handleCollapseAll(data, setExpandedModules)

          // Debounce the API call to persist collapsed state for all modules
          handleToggleAllCollapse(true)
        }}
        onExpandAll={() => {
          // Update UI immediately
          handleExpandAll(data, setExpandedModules)

          // Debounce the API call to persist expanded state for all modules
          // This will automatically set button disabled state and reset it after completion
          handleToggleAllCollapse(false)
        }}
        anyModuleExpanded={Array.from(expandedModules.values()).some(expanded => expanded)}
        disabled={expandCollapseButtonDisabled}
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
            data?.pages
              .flatMap(page => page.modules)
              .map(module => (
                <MemoizedModuleStudent
                  key={module._id}
                  id={module._id}
                  name={module.name}
                  completionRequirements={module.completionRequirements}
                  prerequisites={module.prerequisites}
                  requireSequentialProgress={module.requireSequentialProgress}
                  progression={module.progression}
                  expanded={!!expandedModules.get(module._id)}
                  onToggleExpand={handleToggleExpandRef}
                  requirementCount={module.requirementCount}
                  submissionStatistics={module.submissionStatistics}
                />
              ))
          )}
        </Flex>
      )}
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
