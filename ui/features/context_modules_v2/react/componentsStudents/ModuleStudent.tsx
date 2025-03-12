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
import {ModuleItemProps} from '../componentsTeacher/ModuleItem'
import ModuleHeaderStudent from './ModuleHeaderStudent'
import ModuleItemListStudent from './ModuleItemListStudent'
import {useModuleItems} from '../hooks/queries/useModuleItems'
import {CompletionRequirement, ModuleItem} from '../utils/types'

export interface ModuleStudentProps {
  id: string
  name: string
  completionRequirements?: CompletionRequirement[]
  expanded?: boolean
  onToggleExpand?: (id: string) => void
}

const ModuleStudent: React.FC<ModuleStudentProps> = ({
  id,
  completionRequirements,
  expanded: propExpanded,
  onToggleExpand,
  name,
}) => {
  const [isExpanded, setIsExpanded] = useState(propExpanded !== undefined ? propExpanded : false)
  const {data, isLoading, error} = useModuleItems(id, !!isExpanded)
  const [moduleItems, setModuleItems] = useState<ModuleItemProps[]>([])

  const toggleExpanded = (moduleId: string) => {
    const newExpandedState = !isExpanded;
    setIsExpanded(newExpandedState);
    if (onToggleExpand) {
      onToggleExpand(moduleId);
    }
  }

  useEffect(() => {
    if (isExpanded && data?.moduleItems && data.moduleItems.length > 0) {
      const transformedItems = data.moduleItems.map((item: ModuleItem, index: number) => ({
        ...item,
        moduleId: id,
        index,
        content: item.content ? {
          ...item.content,
          id: item.content.id || item._id,
          type: item.content.type || 'unknown',
        } : null
      }));
      setModuleItems(transformedItems);
    }
  }, [data, id])

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
        <ModuleHeaderStudent
            id={id}
            name={name}
            expanded={isExpanded}
            onToggleExpand={toggleExpanded}
          />
        </Flex.Item>
      {isExpanded && (
        <Flex.Item>
          <ModuleItemListStudent
            moduleItems={moduleItems}
            completionRequirements={completionRequirements}
            isLoading={isLoading}
            error={error}
          />
        </Flex.Item>
      )}
      </Flex>
    </View>
  )
}

export default ModuleStudent
