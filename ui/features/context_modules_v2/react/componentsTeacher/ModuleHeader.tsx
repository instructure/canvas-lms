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
import {Text} from '@instructure/ui-text'
import ModuleHeaderUnlockAt from '../components/ModuleHeaderUnlockAt'
import {isModuleUnlockAtDateInTheFuture} from '../utils/utils'

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
  unlockAt: string | null
  dragHandleProps?: any // For react-beautiful-dnd drag handle
  hasActiveOverrides: boolean
  showAll?: boolean
  onToggleShowAll?: (id: string) => void
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
  unlockAt,
  dragHandleProps,
  hasActiveOverrides,
  showAll = false,
  onToggleShowAll,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  const onToggleExpandRef = useCallback(() => {
    onToggleExpand(id)
  }, [onToggleExpand, id])

  return (
    <View as="div" background="secondary" borderWidth="0 0 small 0">
      <Flex padding="small" justifyItems="space-between" alignItems="center" wrap="wrap">
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
                data-testid="module-header-expand-toggle"
                aria-expanded={expanded}
              />
            </Flex.Item>
            <Flex.Item padding="0 0 x-small 0" shouldGrow shouldShrink>
              <Flex direction="column" as="div" margin="none">
                <Flex.Item margin="none">
                  <Heading level="h2">
                    <Text size="medium" weight="bold" wrap="break-word">
                      {name}
                    </Text>
                  </Heading>
                </Flex.Item>
                {(unlockAt && isModuleUnlockAtDateInTheFuture(unlockAt)) ||
                prerequisites?.length ? (
                  <Flex.Item margin="none">
                    <Flex gap="xx-small" alignItems="center" wrap="wrap">
                      {unlockAt && isModuleUnlockAtDateInTheFuture(unlockAt) && (
                        <Flex.Item>
                          <ModuleHeaderUnlockAt unlockAt={unlockAt} />
                        </Flex.Item>
                      )}
                      {unlockAt &&
                        isModuleUnlockAtDateInTheFuture(unlockAt) &&
                        prerequisites?.length && (
                          <Flex.Item>
                            <Text size="x-small" color="secondary" as="span">
                              |
                            </Text>
                          </Flex.Item>
                        )}
                      {prerequisites?.length && (
                        <Flex.Item>
                          <Text
                            size="x-small"
                            color="secondary"
                            data-testid="module-header-prerequisites"
                          >
                            {I18n.t(
                              {
                                one: 'Prerequisite: %{prerequisiteName}',
                                other: 'Prerequisites: %{prerequisiteName}',
                              },
                              {
                                count: prerequisites.length,
                                prerequisiteName: prerequisites.map(p => p.name).join(', '),
                              },
                            )}
                          </Text>
                        </Flex.Item>
                      )}
                    </Flex>
                  </Flex.Item>
                ) : null}
              </Flex>
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
            hasActiveOverrides={hasActiveOverrides}
            showAll={showAll}
            onToggleShowAll={onToggleShowAll}
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
