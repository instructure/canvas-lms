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

import React, {useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconDragHandleLine,
  IconMiniArrowEndSolid,
  IconMiniArrowDownLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleHeaderActionPanel from './ModuleHeaderActionPanel'
import {CompletionRequirement, Prerequisite, ModuleAction} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

interface ModuleHeaderProps {
  id: string
  name: string
  expanded: boolean
  onToggleExpand: (id: string) => void
  published: boolean
  prerequisites?: Prerequisite[]
  completionRequirements?: CompletionRequirement[]
  requirementCount: number
  dragHandleProps?: any // For react-beautiful-dnd drag handle
  hasActiveOverrides: boolean
  itemCount: number
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const ModuleHeader: React.FC<ModuleHeaderProps> = ({
  id,
  name,
  expanded,
  onToggleExpand,
  published,
  prerequisites,
  completionRequirements,
  requirementCount,
  dragHandleProps,
  itemCount,
  hasActiveOverrides,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  const onToggleExpandRef = useCallback(() => {
    onToggleExpand(id)
  }, [onToggleExpand, id])

  return (
    <View as="div" background="secondary" borderWidth="0 0 small 0">
      <Flex padding="small" justifyItems="space-between" wrap="wrap">
        <Flex.Item>
          <Flex gap="small" alignItems="center">
            <Flex.Item>
              <div {...dragHandleProps}>
                <IconDragHandleLine />
              </div>
            </Flex.Item>
            <Flex.Item>
              <IconButton
                size="small"
                withBorder={false}
                screenReaderLabel={expanded ? I18n.t('Collapse module') : I18n.t('Expand module')}
                renderIcon={expanded ? IconMiniArrowDownLine : IconMiniArrowEndSolid}
                withBackground={false}
                onClick={onToggleExpandRef}
              />
            </Flex.Item>
            <Flex.Item>
              <Heading level="h3">{name}</Heading>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <ModuleHeaderActionPanel
            id={id}
            name={name}
            expanded={expanded}
            published={published}
            prerequisites={prerequisites}
            completionRequirements={completionRequirements}
            requirementCount={requirementCount || undefined}
            itemCount={itemCount}
            hasActiveOverrides={hasActiveOverrides}
            setModuleAction={setModuleAction}
            setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
            setSourceModule={setSourceModule}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleHeader
