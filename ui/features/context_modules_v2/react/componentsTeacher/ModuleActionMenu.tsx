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
import ExternalToolTrayLauncher from './ExternalToolTrayLauncher'
import ExternalToolModalLauncherWrapper from './ExternalToolModalLauncher'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {queryClient} from '@canvas/query'
import {useModules} from '../hooks/queries/useModules'
import {Menu} from '@instructure/ui-menu'
import {
  IconMoreLine,
  IconEditLine,
  IconMoveDownLine,
  IconUpdownLine,
  IconPermissionsSolid,
  IconTrashLine,
  IconCopySolid,
  IconUserLine,
  IconDuplicateLine,
} from '@instructure/ui-icons'
import {
  handleDelete,
  handleDuplicate,
  handleSendTo,
  handleCopyTo,
} from '../handlers/moduleActionHandlers'
import {handleOpeningModuleUpdateTray} from '../handlers/modulePageActionHandlers'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'
import {ModuleAction, ExternalTool, ExternalToolPlacementType} from '../utils/types'
import {useExternalToolLaunch} from '../hooks/useExternalToolLaunch'
import {useModuleItems} from '../hooks/queries/useModuleItems'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleActionMenuProps {
  expanded: boolean
  isMenuOpen: boolean
  setIsMenuOpen: React.Dispatch<React.SetStateAction<boolean>>
  id: string
  name: string
  prerequisites?: {id: string; name: string; type: string}[]
  setIsDirectShareOpen: React.Dispatch<React.SetStateAction<boolean>>
  setIsDirectShareCourseOpen: React.Dispatch<React.SetStateAction<boolean>>
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const ModuleActionMenu: React.FC<ModuleActionMenuProps> = ({
  expanded,
  isMenuOpen,
  setIsMenuOpen,
  id,
  name,
  prerequisites,
  setIsDirectShareOpen,
  setIsDirectShareCourseOpen,
  setModuleAction,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  const {courseId, permissions} = useContextModule()
  const {data, isLoading, isError} = useModules(courseId)
  const {
    launchState,
    launchExternalTool,
    closeLaunch,
    moduleGroupMenuTools,
    moduleMenuModalTools,
    moduleMenuTools,
  } = useExternalToolLaunch()

  const {data: moduleItems} = useModuleItems(id, null, expanded || isMenuOpen)

  const handleEditRef = useCallback(() => {
    handleOpeningModuleUpdateTray(
      data,
      courseId,
      id,
      name,
      prerequisites,
      'settings',
      moduleItems?.moduleItems,
    )
  }, [data, courseId, id, name, prerequisites, moduleItems])

  const handleMoveContentsRef = useCallback(() => {
    if (!data || !setModuleAction || !setIsManageModuleContentTrayOpen) return

    if (setSourceModule) {
      setSourceModule({id, title: name})
    }

    setModuleAction('move_module_contents')
    setIsManageModuleContentTrayOpen(true)
    setIsMenuOpen(false)
  }, [
    data,
    id,
    name,
    setModuleAction,
    setIsManageModuleContentTrayOpen,
    setIsMenuOpen,
    setSourceModule,
  ])

  const handleMoveModuleRef = useCallback(() => {
    if (!data || !setModuleAction || !setIsManageModuleContentTrayOpen) return

    if (setSourceModule) {
      setSourceModule({id, title: name})
    }

    setModuleAction('move_module')
    setIsManageModuleContentTrayOpen(true)
    setIsMenuOpen(false)
  }, [
    data,
    id,
    name,
    setModuleAction,
    setIsManageModuleContentTrayOpen,
    setIsMenuOpen,
    setSourceModule,
  ])

  const handleAssignToRef = useCallback(() => {
    handleOpeningModuleUpdateTray(
      data,
      courseId,
      id,
      name,
      prerequisites,
      'assign-to',
      moduleItems?.moduleItems,
    )
  }, [data, courseId, id, name, prerequisites, moduleItems])

  const handleDeleteRef = useCallback(() => {
    handleDelete(id, name, queryClient, courseId, setIsMenuOpen)
  }, [id, name, courseId, setIsMenuOpen])

  const handleDuplicateRef = useCallback(() => {
    handleDuplicate(id, name, queryClient, courseId, setIsMenuOpen)
  }, [id, name, courseId, setIsMenuOpen])

  const handleSendToRef = useCallback(() => {
    handleSendTo(setIsDirectShareOpen)
  }, [setIsDirectShareOpen])

  const handleCopyToRef = useCallback(() => {
    handleCopyTo(setIsDirectShareCourseOpen)
  }, [setIsDirectShareCourseOpen])

  const canDuplicate =
    moduleItems?.moduleItems.every(item => item.content?.canDuplicate) && expanded

  const handleExternalToolLaunch = useCallback(
    (tool: ExternalTool, placement: ExternalToolPlacementType) => {
      launchExternalTool(tool, id, placement)
      setIsMenuOpen(false)
    },
    [launchExternalTool, id, setIsMenuOpen],
  )

  const renderExternalToolMenuItems = () => {
    const allTools = [
      ...moduleMenuTools.map(tool => ({...tool, placement: 'module_menu' as const})),
      ...moduleGroupMenuTools.map(tool => ({...tool, placement: 'module_group_menu' as const})),
      ...moduleMenuModalTools.map(tool => ({...tool, placement: 'module_menu_modal' as const})),
    ]

    return allTools.map(tool => {
      // Get the right identifier and name based on tool structure
      const toolId = 'id' in tool ? tool.id : tool.definition_id
      const toolName = 'title' in tool ? tool.title : tool.name

      return (
        <Menu.Item
          key={`${tool.placement}-${toolId}`}
          onClick={() => handleExternalToolLaunch(tool, tool.placement)}
        >
          <Flex>
            <Flex.Item margin="0 0 0 x-small">{toolName}</Flex.Item>
          </Flex>
        </Menu.Item>
      )
    })
  }

  return (
    <>
      <Menu
        onToggle={isOpen => setIsMenuOpen(isOpen)}
        open={isMenuOpen}
        trigger={
          <IconButton
            screenReaderLabel={I18n.t('Module Options')}
            data-testid={`module-action-menu_${id}`}
            renderIcon={IconMoreLine}
            withBackground={false}
            withBorder={false}
            size="small"
            disabled={isLoading || isError}
          />
        }
      >
        {permissions?.canEdit && (
          <Menu.Item onClick={handleEditRef}>
            <Flex>
              <Flex.Item>
                <IconEditLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Edit')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canEdit && (
          <Menu.Item onClick={handleMoveContentsRef}>
            <Flex>
              <Flex.Item>
                <IconMoveDownLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Move Contents...')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canEdit && (
          <Menu.Item onClick={handleMoveModuleRef}>
            <Flex>
              <Flex.Item>
                <IconUpdownLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Move Module...')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canEdit && (
          <Menu.Item onClick={handleAssignToRef}>
            <Flex>
              <Flex.Item>
                <IconPermissionsSolid />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Assign To...')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canDelete && (
          <Menu.Item data-testid={`module-action-menu_${id}-deletion`} onClick={handleDeleteRef}>
            <Flex>
              <Flex.Item>
                <IconTrashLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Delete')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canAdd && canDuplicate && (
          <Menu.Item onClick={handleDuplicateRef}>
            <Flex>
              <Flex.Item>
                <IconDuplicateLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Duplicate')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canDirectShare && (
          <Menu.Item onClick={handleSendToRef}>
            <Flex>
              <Flex.Item>
                <IconUserLine />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Send To...')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {permissions?.canDirectShare && (
          <Menu.Item data-testid={`module-action-menu_${id}-copy`} onClick={handleCopyToRef}>
            <Flex>
              <Flex.Item>
                <IconCopySolid />
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">{I18n.t('Copy To...')}</Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        {renderExternalToolMenuItems()}
      </Menu>
      {launchState.isTrayOpen && launchState.selectedTool && (
        <ExternalToolTrayLauncher
          tool={launchState.selectedTool}
          isOpen={true}
          onClose={closeLaunch}
          contextModuleId={launchState.contextModuleId || ''}
          launchType={launchState.launchType || 'module_group_menu'}
          moduleId={id}
          expanded={expanded}
          isMenuOpen={isMenuOpen}
        />
      )}
      {launchState.isModalOpen && launchState.selectedTool && (
        <ExternalToolModalLauncherWrapper
          tool={launchState.selectedTool}
          isOpen={true}
          onClose={closeLaunch}
          contextModuleId={launchState.contextModuleId}
          launchType={launchState.launchType || 'module_menu_modal'}
        />
      )}
    </>
  )
}

export default ModuleActionMenu
