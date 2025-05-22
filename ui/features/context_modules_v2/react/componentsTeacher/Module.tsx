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
import {useModuleItems} from '../hooks/queries/useModuleItems'
import {Prerequisite, CompletionRequirement, ModuleAction} from '../utils/types'

export interface ModuleProps {
  id: string
  name: string
  published?: boolean
  prerequisites?: Prerequisite[]
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
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
  requirementCount,
  dragHandleProps,
  expanded: propExpanded,
  hasActiveOverrides,
  onToggleExpand,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSelectedModuleItem,
  setSourceModule: setSourceModule,
}) => {
  const [isExpanded, setIsExpanded] = useState(propExpanded !== undefined ? propExpanded : false)
  const {data, isLoading, error} = useModuleItems(id, !!isExpanded)

  const toggleExpanded = () => {
    const newExpandedState = !isExpanded
    setIsExpanded(newExpandedState)
    if (onToggleExpand) {
      onToggleExpand(id)
    }
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
      className={`context_module module_${id}`}
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
            dragHandleProps={dragHandleProps}
            itemCount={data?.moduleItems?.length || 0}
            hasActiveOverrides={hasActiveOverrides}
            setModuleAction={setModuleAction}
            setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
            setSourceModule={setSourceModule}
          />
        </Flex.Item>
        {isExpanded && (
          <Flex.Item>
            <ModuleItemList
              moduleId={id}
              moduleTitle={name}
              moduleItems={data?.moduleItems || []}
              completionRequirements={completionRequirements}
              isLoading={isLoading}
              error={error}
              setModuleAction={setModuleAction}
              setSelectedModuleItem={setSelectedModuleItem}
              setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
              setSourceModule={setSourceModule}
            />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default Module
