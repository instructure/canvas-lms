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

import React, {useCallback, useState, useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {
  IconMoreLine,
  IconDownloadLine,
  IconTrashLine,
  IconCloudLockLine,
  IconExpandItemsLine,
  IconPermissionsLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {DeleteModal} from './DeleteModal'
import {type File, type Folder} from '../../../interfaces/File'
import {getUniqueId} from '../../../utils/fileFolderUtils'
import {downloadZip} from '../../../utils/downloadUtils'
import MoveModal from './MoveModal'
import UsageRightsModal from './UsageRightsModal'
import PermissionsModal from './PermissionsModal'
import {DisabledActionsInfoButton} from './DisabledActionsInfoButton'

const I18n = createI18nScope('files_v2')

export interface BulkActionButtonsProps {
  size: 'small' | 'medium' | 'large'
  selectedRows: Set<string>
  totalRows: number
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  userCanRestrictFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  rows: (File | Folder)[]
}

type BulkActionModalOrTrayId = 'delete' | 'move-to' | 'manage-usage-rights' | 'permissions'

const BulkActionButtons = ({
  size,
  selectedRows,
  totalRows,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  userCanRestrictFilesForContext,
  usageRightsRequiredForContext,
  rows,
}: BulkActionButtonsProps) => {
  const [modalOrTray, setModalOrTray] = useState<BulkActionModalOrTrayId | null>(null)
  const isEnabled = selectedRows.size >= 1
  const containsLockedBPItems = useMemo(
    () =>
      rows.some(
        row =>
          selectedRows.has(getUniqueId(row)) &&
          !row.is_master_course_master_content &&
          row.restricted_by_master_course,
      ),
    [rows, selectedRows],
  )

  const selectedText = !isEnabled
    ? I18n.t('0 selected')
    : I18n.t('%{selected} of %{total} selected', {selected: selectedRows.size, total: totalRows})

  const isSmallScreen = size === 'small'
  const buttonDisplay = isSmallScreen ? 'block' : 'inline-block'
  const justifyItems = isSmallScreen ? 'space-between' : 'end'
  const direction = isSmallScreen ? 'column' : 'row'

  const onDismissModalOrTray = useCallback(() => setModalOrTray(null), [])
  const createSetModalOrTrayCallback = useCallback(
    (id: BulkActionModalOrTrayId | null) => () => setModalOrTray(id),
    [],
  )

  const handleDownload = useCallback(() => downloadZip(selectedRows), [selectedRows])

  const selectedItems = rows.filter(row => selectedRows.has(getUniqueId(row)))

  const buildModals = useCallback(
    () => (
      <>
        <DeleteModal
          open={modalOrTray === 'delete'}
          items={selectedItems}
          onClose={onDismissModalOrTray}
        />
        <MoveModal
          items={selectedItems}
          open={modalOrTray === 'move-to'}
          onDismiss={onDismissModalOrTray}
        />
        <UsageRightsModal
          items={selectedItems}
          open={modalOrTray === 'manage-usage-rights'}
          onDismiss={onDismissModalOrTray}
        />
        <PermissionsModal
          items={selectedItems}
          open={modalOrTray === 'permissions'}
          onDismiss={onDismissModalOrTray}
        />
      </>
    ),
    [modalOrTray, onDismissModalOrTray, selectedItems],
  )

  const getTooltipText = useCallback((): string | undefined => {
    if (!isEnabled) {
      return I18n.t('Please select an item first.')
    } else if (containsLockedBPItems) {
      return I18n.t('Unselect locked items first.')
    } else {
      return
    }
  }, [isEnabled, containsLockedBPItems])

  const renderTooltip = (child: React.ReactNode, disabled: boolean) => {
    // only render the tool tip if the action is disabled
    if (disabled) {
      return (
        <Tooltip renderTip={getTooltipText()} on={['hover', 'focus']}>
          {child}
        </Tooltip>
      )
    } else {
      return child
    }
  }

  return (
    <>
      <Flex gap="small" justifyItems={justifyItems} direction={direction}>
        <Flex gap="small">
          <Flex.Item>
            <Text>{selectedText}</Text>
          </Flex.Item>
          {ENV.BLUEPRINT_COURSES_DATA?.isChildCourse && <DisabledActionsInfoButton size={size} />}
        </Flex>
        <Flex gap="small" direction={direction}>
          {renderTooltip(
            <Button
              data-testid="bulk-actions-download-button"
              disabled={!isEnabled}
              renderIcon={<IconDownloadLine />}
              onClick={handleDownload}
              display={buttonDisplay}
            >
              {isSmallScreen ? (
                I18n.t('Download')
              ) : (
                <ScreenReaderContent>{I18n.t('Download')}</ScreenReaderContent>
              )}
            </Button>,
            !isEnabled,
          )}
          {userCanDeleteFilesForContext &&
            renderTooltip(
              <Button
                data-testid="bulk-actions-delete-button"
                disabled={!isEnabled || containsLockedBPItems}
                renderIcon={<IconTrashLine />}
                onClick={createSetModalOrTrayCallback('delete')}
                display={buttonDisplay}
              >
                {isSmallScreen ? (
                  I18n.t('Delete')
                ) : (
                  <ScreenReaderContent>{I18n.t('Delete')}</ScreenReaderContent>
                )}
              </Button>,
              !isEnabled || containsLockedBPItems,
            )}
          {userCanEditFilesForContext &&
            renderTooltip(
              <Flex.Item>
                <Menu
                  placement="bottom"
                  trigger={
                    <Button
                      renderIcon={<IconMoreLine />}
                      disabled={!isEnabled}
                      data-testid="bulk-actions-more-button"
                      display={buttonDisplay}
                    >
                      {isSmallScreen ? (
                        I18n.t('More')
                      ) : (
                        <ScreenReaderContent>{I18n.t('Bulk Actions')}</ScreenReaderContent>
                      )}
                    </Button>
                  }
                >
                  {userCanRestrictFilesForContext && (
                    <Menu.Item
                      disabled={containsLockedBPItems}
                      data-testid="bulk-actions-edit-permissions-button"
                      onClick={createSetModalOrTrayCallback('permissions')}
                    >
                      <Flex alignItems="center" gap="x-small">
                        <Flex.Item>
                          <IconPermissionsLine inline={false} />
                        </Flex.Item>
                        <Flex.Item>
                          <Text>{I18n.t('Edit Permissions')}</Text>
                        </Flex.Item>
                      </Flex>
                    </Menu.Item>
                  )}
                  {userCanEditFilesForContext && usageRightsRequiredForContext && (
                    <Menu.Item
                      disabled={containsLockedBPItems}
                      data-testid="bulk-actions-manage-usage-rights-button"
                      onClick={createSetModalOrTrayCallback('manage-usage-rights')}
                    >
                      <Flex alignItems="center" gap="x-small">
                        <Flex.Item>
                          <IconCloudLockLine inline={false} />
                        </Flex.Item>
                        <Flex.Item>
                          <Text>{I18n.t('Manage Usage Rights')}</Text>
                        </Flex.Item>
                      </Flex>
                    </Menu.Item>
                  )}
                  {userCanEditFilesForContext && (
                    <Menu.Item
                      disabled={containsLockedBPItems}
                      data-testid="bulk-actions-move-button"
                      onClick={createSetModalOrTrayCallback('move-to')}
                    >
                      <Flex alignItems="center" gap="x-small">
                        <Flex.Item>
                          <IconExpandItemsLine inline={false} />
                        </Flex.Item>
                        <Flex.Item>
                          <Text>{I18n.t('Move To...')}</Text>
                        </Flex.Item>
                      </Flex>
                    </Menu.Item>
                  )}
                </Menu>
              </Flex.Item>,
              !isEnabled,
            )}
        </Flex>
      </Flex>
      {buildModals()}
    </>
  )
}

export default BulkActionButtons
