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
import React, {useState, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import ModuleHeader from '../componentsTeacher/ModuleHeader'
import ModuleItemList from '../componentsTeacher/ModuleItemList'
import ModuleItemListSmart from '../components/ModuleItemListSmart'
import {Prerequisite, CompletionRequirement, ModuleAction} from '../utils/types'
import {TEACHER} from '../utils/constants'
import {useShowAllState} from '../hooks/useShowAllState'
import {useContextModule} from '../hooks/useModuleContext'

export interface ModuleProps {
  id: string
  name: string
  published?: boolean
  position?: number
  prerequisites?: Prerequisite[]
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  unlockAt: string | null
  dragHandleProps?: any
  expanded?: boolean
  hasActiveOverrides: boolean
  onToggleExpand?: (id: string) => void
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSelectedModuleItem?: (item: {id: string; title: string} | null) => void
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const Module: React.FC<ModuleProps> = ({
  id,
  name,
  published = false,
  prerequisites,
  completionRequirements,
  position,
  requirementCount,
  unlockAt,
  dragHandleProps,
  expanded: propExpanded,
  hasActiveOverrides,
  onToggleExpand,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSelectedModuleItem,
  setSourceModule,
}) => {
  const [isExpanded, setIsExpanded] = useState(propExpanded !== undefined ? propExpanded : false)
  const [showAll, setShowAll] = useShowAllState(id)
  const {modulesArePaginated} = useContextModule()

  const toggleExpanded = () => {
    const newExpandedState = !isExpanded
    setIsExpanded(newExpandedState)
    if (onToggleExpand) {
      onToggleExpand(id)
    }
  }

  const handleToggleShowAll = () => {
    setShowAll(prev => !prev)
  }

  useEffect(() => {
    if (propExpanded !== undefined) {
      setIsExpanded(propExpanded)
    }
  }, [propExpanded])

  return (
    <View
      as="div"
      margin="0 0 0 0"
      padding="0"
      background="primary"
      borderWidth="small"
      borderRadius="medium"
      borderColor="primary"
      shadow="resting"
      overflowX="hidden"
      data-module-id={id}
      data-position={position}
      data-module-name={name}
      className={`context_module module_${id} ${isExpanded ? 'expanded' : 'collapsed'}`}
      id={`context_module_${id}`}
    >
      <Flex direction="column">
        <Flex.Item>
          <ModuleHeader
            id={id}
            name={name}
            expanded={isExpanded}
            onToggleExpand={toggleExpanded}
            published={published}
            prerequisites={prerequisites}
            completionRequirements={completionRequirements}
            requirementCount={requirementCount || 0}
            unlockAt={unlockAt}
            dragHandleProps={dragHandleProps}
            hasActiveOverrides={hasActiveOverrides}
            showAll={showAll}
            onToggleShowAll={handleToggleShowAll}
            setModuleAction={setModuleAction}
            setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
            setSourceModule={setSourceModule}
          />
        </Flex.Item>
        {isExpanded && (
          <Flex.Item>
            <ModuleItemListSmart
              moduleId={id}
              view={TEACHER}
              isExpanded={isExpanded}
              isPaginated={modulesArePaginated && !showAll}
              renderList={({moduleItems, isEmpty, error}) => (
                <ModuleItemList
                  moduleId={id}
                  moduleTitle={name}
                  moduleItems={moduleItems}
                  completionRequirements={completionRequirements}
                  error={error}
                  setModuleAction={setModuleAction}
                  setSelectedModuleItem={setSelectedModuleItem}
                  setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
                  setSourceModule={setSourceModule}
                  isEmpty={isEmpty}
                />
              )}
            />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default Module
