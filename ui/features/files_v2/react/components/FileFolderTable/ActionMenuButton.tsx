/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useMemo, useState} from 'react'
import {assignLocation} from '@canvas/util/globalUtils'
import {Button, IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useFileManagement} from '../../contexts/FileManagementContext'
import {useRowFocus} from '../../contexts/RowFocusContext'
import {type File, type Folder} from '../../../interfaces/File'
import {RenameModal} from '../RenameModal'
import {DeleteModal} from './DeleteModal'
import {downloadFile, downloadZip} from '../../../utils/downloadUtils'
import {getName, isFile, isLockedBlueprintItem} from '../../../utils/fileFolderUtils'
import {externalToolEnabled} from '../../../utils/fileUtils'

import {
  IconMoreLine,
  IconArrowOpenDownLine,
  IconDownloadLine,
  IconTrashLine,
  IconEditLine,
  IconUserLine,
  IconDuplicateLine,
  IconPermissionsLine,
  IconCloudLockLine,
  IconExpandItemsLine,
} from '@instructure/ui-icons'
import DirectShareUserTray from './DirectShareUserTray'
import DirectShareCourseTray from './DirectShareCourseTray'
import MoveModal from './MoveModal'
import UsageRightsModal from './UsageRightsModal'
import PermissionsModal from './PermissionsModal'

const I18n = createI18nScope('files_v2')

export interface ActionMenuButtonProps {
  size: 'small' | 'medium' | 'large'
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  userCanRestrictFilesForContext: boolean
  row: File | Folder
  rowIndex: number
}

type ActionMenuModalOrTrayId =
  | 'rename'
  | 'delete'
  | 'copy-to'
  | 'send-to'
  | 'move-to'
  | 'manage-usage-rights'
  | 'permissions'

const ActionMenuButton = ({
  size,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  usageRightsRequiredForContext,
  userCanRestrictFilesForContext,
  row,
  rowIndex,
}: ActionMenuButtonProps) => {
  const [modalOrTray, setModalOrTray] = useState<ActionMenuModalOrTrayId | null>(null)
  const name = getName(row)
  const actionLabel = I18n.t('Actions for "%{name}"', {name})
  const {contextType, fileMenuTools} = useFileManagement()
  const {handleActionButtonRef} = useRowFocus()

  const iconForTrayTool = useCallback((tool: {canvas_icon_class?: string; icon_url?: string}) => {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon lti_tool_icon" alt="" src={tool.icon_url} />
    }
    return <></>
  }, [])

  const triggerButton = useCallback(() => {
    return size !== 'large' ? (
      <Button
        display={size == 'small' ? 'block' : 'inline-block'}
        data-testid="action-menu-button-small"
        elementRef={elt => elt?.setAttribute('aria-label', actionLabel)}
      >
        {I18n.t('Actions')} <IconArrowOpenDownLine />
      </Button>
    ) : (
      <IconButton
        renderIcon={IconMoreLine}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={actionLabel}
        data-testid="action-menu-button-large"
      />
    )
  }, [actionLabel, size])

  const renderMenuItem = useCallback(
    (
      index: number,
      {
        icon,
        text,
        separator,
        onClick,
        disabled = false,
      }: {
        icon?: any
        text?: string
        separator?: boolean
        visible?: boolean
        onClick?: (e: React.MouseEvent) => void
        disabled?: boolean
      },
    ) => {
      const key = index + '-' + row.id
      if (separator) {
        return <Menu.Separator key={key} />
      }
      return (
        <Menu.Item
          key={key}
          onClick={onClick}
          disabled={disabled}
          data-testid={`action-menu-button-${text}`}
        >
          <Flex alignItems="center" gap="x-small">
            {typeof icon === 'object' ? (
              <Flex.Item>{icon}</Flex.Item>
            ) : (
              <Flex.Item>{React.createElement(icon, {inline: false})}</Flex.Item>
            )}
            <Flex.Item>
              <Text>{text}</Text>
            </Flex.Item>
          </Flex>
        </Menu.Item>
      )
    },
    [row.id],
  )

  const onDismissModalOrTray = useCallback(() => setModalOrTray(null), [])
  const createSetModalOrTrayCallback = useCallback(
    (id: ActionMenuModalOrTrayId | null) => () => setModalOrTray(id),
    [],
  )

  const blueprint_locked = isLockedBlueprintItem(row)
  const has_usage_rights = userCanEditFilesForContext && usageRightsRequiredForContext
  const send_copy_permissions = contextType === 'course' && userCanEditFilesForContext
  const rename_move_permissions = userCanEditFilesForContext && !blueprint_locked
  const delete_permissions = userCanDeleteFilesForContext && !blueprint_locked

  const filteredItems = useMemo(
    () =>
      (isFile(row)
        ? [
            // files
            {
              icon: IconEditLine,
              text: I18n.t('Rename'),
              visible: rename_move_permissions,
              onClick: createSetModalOrTrayCallback('rename'),
            },
            {
              icon: IconDownloadLine,
              text: I18n.t('Download'),
              onClick: () => downloadFile(row.url),
            },
            {
              icon: IconPermissionsLine,
              text: I18n.t('Edit Permissions'),
              visible: userCanRestrictFilesForContext,
              onClick: createSetModalOrTrayCallback('permissions'),
            },
            {
              icon: IconCloudLockLine,
              text: I18n.t('Manage Usage Rights'),
              visible: has_usage_rights,
              onClick: createSetModalOrTrayCallback('manage-usage-rights'),
            },
            {
              icon: IconUserLine,
              text: I18n.t('Send To...'),
              visible: send_copy_permissions,
              onClick: createSetModalOrTrayCallback('send-to'),
            },
            {
              icon: IconDuplicateLine,
              text: I18n.t('Copy To...'),
              visible: send_copy_permissions,
              onClick: createSetModalOrTrayCallback('copy-to'),
            },
            {
              icon: IconExpandItemsLine,
              text: I18n.t('Move To...'),
              visible: rename_move_permissions,
              onClick: createSetModalOrTrayCallback('move-to'),
            },
            ...fileMenuTools.map(tool => {
              return {
                icon: iconForTrayTool(tool),
                text: tool.title,
                onClick: () => assignLocation(`${tool.base_url}&files[]=${row.id}`),
                visible: true,
                disabled: !externalToolEnabled(row, tool),
              }
            }),
            {separator: true, visible: delete_permissions},
            {
              icon: IconTrashLine,
              text: I18n.t('Delete'),
              visible: delete_permissions,
              onClick: createSetModalOrTrayCallback('delete'),
            },
          ]
        : [
            // folder
            {
              icon: IconEditLine,
              text: I18n.t('Rename'),
              visible: rename_move_permissions,
              onClick: createSetModalOrTrayCallback('rename'),
            },
            {
              icon: IconDownloadLine,
              text: I18n.t('Download'),
              onClick: () => downloadZip(new Set([`folder-${row.id.toString()}`])),
            },
            {
              icon: IconPermissionsLine,
              text: I18n.t('Edit Permissions'),
              visible: userCanRestrictFilesForContext,
              onClick: createSetModalOrTrayCallback('permissions'),
            },
            {
              icon: IconCloudLockLine,
              text: I18n.t('Manage Usage Rights'),
              visible: has_usage_rights,
              onClick: createSetModalOrTrayCallback('manage-usage-rights'),
            },
            {
              icon: IconExpandItemsLine,
              text: I18n.t('Move To...'),
              visible: rename_move_permissions,
              onClick: createSetModalOrTrayCallback('move-to'),
            },
            {separator: true, visible: delete_permissions},
            {
              icon: IconTrashLine,
              text: I18n.t('Delete'),
              visible: delete_permissions,
              onClick: createSetModalOrTrayCallback('delete'),
            },
          ]
      ).filter(({visible}) => visible !== false),
    [
      row,
      rename_move_permissions,
      createSetModalOrTrayCallback,
      userCanRestrictFilesForContext,
      has_usage_rights,
      send_copy_permissions,
      fileMenuTools,
      delete_permissions,
      iconForTrayTool,
    ],
  )

  const buildTrays = useCallback(() => {
    if (!isFile(row)) return null

    return (
      <>
        {ENV.COURSE_ID && (
          <DirectShareUserTray
            open={modalOrTray === 'send-to'}
            onDismiss={onDismissModalOrTray}
            courseId={ENV.COURSE_ID}
            file={row}
          />
        )}
        {ENV.COURSE_ID && (
          <DirectShareCourseTray
            open={modalOrTray === 'copy-to'}
            onDismiss={onDismissModalOrTray}
            courseId={ENV.COURSE_ID}
            file={row}
          />
        )}
      </>
    )
  }, [modalOrTray, onDismissModalOrTray, row])

  const buildModals = useCallback(() => {
    return (
      <>
        <RenameModal
          renamingItem={row}
          isOpen={modalOrTray === 'rename'}
          onClose={onDismissModalOrTray}
        />
        <DeleteModal
          open={modalOrTray === 'delete'}
          items={[row]}
          onClose={onDismissModalOrTray}
          rowIndex={rowIndex}
        />
        <MoveModal
          items={[row]}
          open={modalOrTray === 'move-to'}
          onDismiss={onDismissModalOrTray}
          rowIndex={rowIndex}
        />
        <UsageRightsModal
          items={[row]}
          open={modalOrTray === 'manage-usage-rights'}
          onDismiss={onDismissModalOrTray}
        />
        <PermissionsModal
          items={[row]}
          open={modalOrTray === 'permissions'}
          onDismiss={onDismissModalOrTray}
        />
      </>
    )
  }, [modalOrTray, onDismissModalOrTray, row, rowIndex])

  return (
    <div ref={el => handleActionButtonRef(el, rowIndex)}>
      <Menu placement="bottom" trigger={triggerButton()}>
        {filteredItems.map((item, i) => renderMenuItem(i, item))}
      </Menu>
      {buildTrays()}
      {buildModals()}
    </div>
  )
}

export default ActionMenuButton
