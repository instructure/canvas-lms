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

import React, {useCallback, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconMoreLine,
  IconDownloadLine,
  IconTrashLine,
  IconEyeLine,
  IconCloudLockLine,
  IconExpandItemsLine,
  IconPermissionsLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {useScope as createI18nScope} from '@canvas/i18n'
import DeleteModal from './DeleteModal'
import {type File, type Folder} from '../../../interfaces/File'
import {getUniqueId} from '../../../utils/fileFolderUtils'
import {downloadZip} from '../../../utils/downloadUtils'
import MoveModal from './MoveModal'

const I18n = createI18nScope('files_v2')

interface BulkActionButtonsProps {
  size: 'small' | 'medium' | 'large'
  selectedRows: Set<string>
  totalRows: number
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  rows: (File | Folder)[]
}

const BulkActionButtons = ({
  size,
  selectedRows,
  totalRows,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  rows,
}: BulkActionButtonsProps) => {
  const [modalOrTray, setModalOrTray] = useState<'delete' | 'move-to' | null>(null)
  const isEnabled = selectedRows.size >= 1
  const selectedText = !isEnabled
    ? I18n.t('0 selected')
    : I18n.t('%{selected} of %{total} selected', {selected: selectedRows.size, total: totalRows})
  const justifyItems = size === 'small' ? 'space-between' : 'end'

  const onDismissModalOrTray = useCallback(() => setModalOrTray(null), [])

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
      </>
    ),
    [modalOrTray, onDismissModalOrTray, selectedItems],
  )

  return (
    <>
      <Flex gap="small" justifyItems={justifyItems}>
        <Flex.Item>
          <Text>{selectedText}</Text>
        </Flex.Item>
        <Flex.Item>
          <Flex gap="small">
            <Flex.Item>
              <IconButton
                disabled={!isEnabled}
                renderIcon={<IconDownloadLine />}
                screenReaderLabel={I18n.t('Download')}
                onClick={handleDownload}
              />
            </Flex.Item>
            {userCanDeleteFilesForContext && (
              <Flex.Item>
                <IconButton
                  data-testid="bulk-actions-delete-button"
                  disabled={!isEnabled}
                  renderIcon={<IconTrashLine />}
                  screenReaderLabel={I18n.t('Delete')}
                  onClick={() => setModalOrTray('delete')}
                />
              </Flex.Item>
            )}
            <Flex.Item>
              <Menu
                placement="bottom"
                trigger={
                  <IconButton
                    renderIcon={<IconMoreLine />}
                    disabled={!isEnabled}
                    screenReaderLabel={I18n.t('Actions')}
                    data-testid="bulk-actions-more-button"
                  />
                }
              >
                <Menu.Item>
                  <Flex alignItems="center" gap="x-small">
                    <Flex.Item>
                      <IconEyeLine inline={false} />
                    </Flex.Item>
                    <Flex.Item>
                      <Text>{I18n.t('View')}</Text>
                    </Flex.Item>
                  </Flex>
                </Menu.Item>

                {userCanEditFilesForContext && (
                  <Menu.Item data-testid="bulk-actions-edit-permissions-button">
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
                {userCanEditFilesForContext && (
                  <Menu.Item data-testid="bulk-actions-manage-usage-rights-button">
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
                    data-testid="bulk-actions-move-button"
                    onClick={() => setModalOrTray('move-to')}
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
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      {buildModals()}
    </>
  )
}

export default BulkActionButtons
