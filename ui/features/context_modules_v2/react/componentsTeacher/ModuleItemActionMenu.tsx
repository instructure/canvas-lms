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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {
  IconMoreLine,
  IconArrowEndLine,
  IconArrowStartLine,
  IconEditLine,
  IconSpeedGraderLine,
  IconPermissionsSolid,
  IconDuplicateLine,
  IconUpdownLine,
  IconUserLine,
  IconDuplicateSolid,
  IconTrashLine,
  IconMasteryPathsLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../hooks/useModuleContext'
import type {ModuleItemContent} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

const basicContentTypes = ['SubHeader', 'ExternalUrl']

export interface ModuleItemActionMenuProps {
  moduleId: string
  itemType: string
  content: ModuleItemContent
  canDuplicate: boolean
  isMenuOpen: boolean
  setIsMenuOpen: (isOpen: boolean) => void
  indent: number
  handleEdit: () => void
  handleSpeedGrader: () => void
  handleAssignTo: () => void
  handleDuplicate: () => void
  handleMoveTo: () => void
  handleDecreaseIndent: () => void
  handleIncreaseIndent: () => void
  handleSendTo: () => void
  handleCopyTo: () => void
  handleRemove: () => void
  masteryPathsData?: {
    isCyoeAble: boolean
    isTrigger: boolean
    isReleased: boolean
    releasedLabel: string | null
  } | null
  handleMasteryPaths?: () => void
}

const ModuleItemActionMenu: React.FC<ModuleItemActionMenuProps> = ({
  moduleId,
  itemType,
  content,
  canDuplicate,
  isMenuOpen,
  setIsMenuOpen,
  indent,
  handleEdit,
  handleSpeedGrader,
  handleAssignTo,
  handleDuplicate,
  handleMoveTo,
  handleDecreaseIndent,
  handleIncreaseIndent,
  handleSendTo,
  handleCopyTo,
  handleRemove,
  masteryPathsData,
  handleMasteryPaths = () => {},
}) => {
  const isBasic = basicContentTypes.includes(itemType)
  const isFile = itemType === 'File'
  const isExternalTool = itemType === 'ExternalTool'
  const {permissions, menuItemLoadingState} = useContextModule()
  const isModuleLoading = !!menuItemLoadingState?.[moduleId]?.state
  const canEdit = permissions?.canEdit
  const canAdd = permissions?.canAdd
  const canManageSpeedGrader = permissions?.canManageSpeedGrader
  const canDirectShare = permissions?.canDirectShare

  const isNotSpecialType = !isBasic && !isFile && !isExternalTool
  const showSpeedGrader =
    canManageSpeedGrader &&
    (itemType === 'Assignment' || itemType === 'Quiz') &&
    !!content?.published
  const showAssignTo = !!content?.canManageAssignTo
  const showDirectShare = canDirectShare && isNotSpecialType

  const renderMenuItem = (condition: boolean, handler: () => void, icon: any, label: string) => {
    if (!condition) return null
    return (
      <Menu.Item onClick={isModuleLoading ? undefined : handler} disabled={isModuleLoading}>
        <Flex>
          <Flex.Item>{icon}</Flex.Item>
          <Flex.Item margin="0 0 0 x-small">{label}</Flex.Item>
        </Flex>
      </Menu.Item>
    )
  }

  return (
    <Menu
      onToggle={isOpen => setIsMenuOpen(isOpen)}
      open={isMenuOpen}
      trigger={
        <IconButton
          screenReaderLabel={I18n.t('Module Item Options')}
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          size="small"
          data-testid="module-item-action-menu-button"
        />
      }
      data-testid="module-item-action-menu"
    >
      {renderMenuItem(canEdit, handleEdit, <IconEditLine />, I18n.t('Edit'))}
      {renderMenuItem(
        showSpeedGrader,
        handleSpeedGrader,
        <IconSpeedGraderLine />,
        I18n.t('SpeedGrader'),
      )}
      {renderMenuItem(
        showAssignTo,
        handleAssignTo,
        <IconPermissionsSolid />,
        I18n.t('Assign To...'),
      )}
      {renderMenuItem(
        canAdd && canDuplicate && isNotSpecialType,
        handleDuplicate,
        <IconDuplicateLine />,
        I18n.t('Duplicate'),
      )}
      {renderMenuItem(canEdit, handleMoveTo, <IconUpdownLine />, I18n.t('Move to...'))}
      {renderMenuItem(
        canEdit && indent > 0,
        handleDecreaseIndent,
        <IconArrowStartLine />,
        I18n.t('Decrease indent'),
      )}
      {renderMenuItem(
        canEdit && indent < 5,
        handleIncreaseIndent,
        <IconArrowEndLine />,
        I18n.t('Increase indent'),
      )}
      {renderMenuItem(showDirectShare, handleSendTo, <IconUserLine />, I18n.t('Send To...'))}
      {renderMenuItem(showDirectShare, handleCopyTo, <IconDuplicateSolid />, I18n.t('Copy To...'))}
      {renderMenuItem(
        isNotSpecialType && !!masteryPathsData?.isCyoeAble,
        handleMasteryPaths,
        <IconMasteryPathsLine />,
        masteryPathsData?.isTrigger ? I18n.t('Edit Mastery Paths') : I18n.t('Add Mastery Paths'),
      )}
      {renderMenuItem(canEdit, handleRemove, <IconTrashLine />, I18n.t('Remove'))}
    </Menu>
  )
}

export default ModuleItemActionMenu
