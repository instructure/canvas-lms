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

const I18n = createI18nScope('context_modules_v2')

const basicContentTypes = ['SubHeader', 'ExternalUrl']

export interface ModuleItemActionMenuProps {
  itemType: string
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
  itemType,
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
  const {permissions} = useContextModule()
  return (
    <Menu
      onToggle={isOpen => setIsMenuOpen(isOpen)}
      open={isMenuOpen}
      trigger={
        <IconButton
          screenReaderLabel="Module Item Options"
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          size="small"
        />
      }
      data-testid="module-item-action-menu"
    >
      {permissions?.canEdit && (
        <Menu.Item onClick={handleEdit}>
          <Flex>
            <Flex.Item>
              <IconEditLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Edit')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && !basicContentTypes.includes(itemType) && (
        <Menu.Item onClick={handleSpeedGrader}>
          <Flex>
            <Flex.Item>
              <IconSpeedGraderLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('SpeedGrader')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && !basicContentTypes.includes(itemType) && (
        <Menu.Item onClick={handleAssignTo}>
          <Flex>
            <Flex.Item>
              <IconPermissionsSolid />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Assign To...')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canAdd && canDuplicate && !basicContentTypes.includes(itemType) && (
        <Menu.Item onClick={handleDuplicate}>
          <Flex>
            <Flex.Item>
              <IconDuplicateLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Duplicate')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && (
        <Menu.Item onClick={handleMoveTo}>
          <Flex>
            <Flex.Item>
              <IconUpdownLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Move to...')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && indent > 0 && (
        <Menu.Item onClick={handleDecreaseIndent}>
          <Flex>
            <Flex.Item>
              <IconArrowStartLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Decrease indent')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && indent < 5 && (
        <Menu.Item onClick={handleIncreaseIndent}>
          <Flex>
            <Flex.Item>
              <IconArrowEndLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Increase indent')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canDirectShare && !basicContentTypes.includes(itemType) && (
        <Menu.Item onClick={handleSendTo}>
          <Flex>
            <Flex.Item>
              <IconUserLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Send To...')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canDirectShare && !basicContentTypes.includes(itemType) && (
        <Menu.Item onClick={handleCopyTo}>
          <Flex>
            <Flex.Item>
              <IconDuplicateSolid />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Copy To...')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {!basicContentTypes.includes(itemType) && masteryPathsData?.isCyoeAble && (
        <Menu.Item onClick={handleMasteryPaths}>
          <Flex>
            <Flex.Item>
              <IconMasteryPathsLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">
              {masteryPathsData.isTrigger
                ? I18n.t('Edit Mastery Paths')
                : I18n.t('Add Mastery Paths')}
            </Flex.Item>
          </Flex>
        </Menu.Item>
      )}
      {permissions?.canEdit && (
        <Menu.Item onClick={handleRemove}>
          <Flex>
            <Flex.Item>
              <IconTrashLine />
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">{I18n.t('Remove')}</Flex.Item>
          </Flex>
        </Menu.Item>
      )}
    </Menu>
  )
}

export default ModuleItemActionMenu
