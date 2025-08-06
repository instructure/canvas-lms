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

import React, {useCallback, useState, useMemo, Ref} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {type File, type Folder} from '../../../interfaces/File'
import {ModalOrTrayOptions, type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {type SelectionHandler} from '../../../interfaces/SelectionHandler'
import {pluralizeContextTypeString} from '../../../utils/fileFolderUtils'
import {useHandleKbdShortcuts} from '../../hooks/useHandleKbdShortcuts'
import SubTableContent from './SubTableContent'
import renderTableHead from './RenderTableHead'
import TableBody from './TableBody'
import {useFileManagement} from '../../contexts/FileManagementContext'
import {Alert} from '@instructure/ui-alerts'
import UsageRightsModal from './UsageRightsModal'
import PermissionsModal from './PermissionsModal'
import {Sort} from '../../hooks/useGetPaginatedFiles'
import {createPortal} from 'react-dom'
import {getColumnHeaders, setColumnWidths, type ColumnID} from './FileFolderTableUtils'
import {DragAndDropWrapper} from './DragAndDropWrapper'
import {getFilesEnv} from '../../../utils/filesEnvUtils'

const I18n = createI18nScope('files_v2')

export interface FileFolderTableProps {
  size: 'small' | 'medium' | 'large'
  rows: (File | Folder)[]
  isLoading: boolean
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  userCanRestrictFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  sort: Sort
  onSortChange: (sort: Sort) => void
  searchString?: string
  selectedRows: Set<string>
  selectionHandler: SelectionHandler
  handleFileDropRef?: (el: HTMLInputElement | null) => void
  selectAllRef?: Ref<Checkbox>
  onPreviewFile?: (file: File) => void
}

const FileFolderTable = ({
  size,
  rows,
  isLoading,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  userCanRestrictFilesForContext,
  usageRightsRequiredForContext,
  sort,
  onSortChange,
  searchString = '',
  selectedRows,
  selectionHandler,
  handleFileDropRef,
  selectAllRef,
  onPreviewFile,
}: FileFolderTableProps) => {
  const {currentFolder, contextId, contextType} = useFileManagement()
  const isStacked = size !== 'large'
  const columnHeaders: ColumnHeader[] = useMemo(() => {
    const actionsTitle = isStacked ? '' : I18n.t('Actions')
    const headers = getColumnHeaders(actionsTitle, sort.by)
    setColumnWidths(headers)
    return headers
  }, [isStacked, sort.by])

  const [modalOrTrayOptions, _setModalOrTrayOptions] = useState<ModalOrTrayOptions | null>(null)

  const setModalOrTrayOptions = useCallback(
    (options: ModalOrTrayOptions | null) => () => _setModalOrTrayOptions(options),
    [],
  )

  useHandleKbdShortcuts(selectionHandler.selectAll, selectionHandler.deselectAll)

  enum SortOrder {
    ASCENDING = 'asc',
    DESCENDING = 'desc',
  }

  const handleColumnHeaderClick = useCallback(
    (columnId: ColumnID) => {
      const newCol = columnId
      const newDirection =
        columnId === sort.by
          ? sort.direction === SortOrder.ASCENDING
            ? SortOrder.DESCENDING
            : SortOrder.ASCENDING
          : SortOrder.ASCENDING
      onSortChange({by: newCol, direction: newDirection})
    },
    [SortOrder.ASCENDING, SortOrder.DESCENDING, onSortChange, sort.by, sort.direction],
  )

  const allRowsSelected = rows.length != 0 && selectedRows.size === rows.length
  const someRowsSelected = selectedRows.size > 0 && !allRowsSelected
  const filteredColumns = columnHeaders.filter(column => {
    switch (column.id) {
      case 'rights':
        return usageRightsRequiredForContext
      case 'blueprint':
        return !!ENV.BLUEPRINT_COURSES_DATA
      case 'permissions':
        return contextType !== 'group'
      default:
        return true
    }
  })

  const renderModals = useCallback(
    () =>
      createPortal(
        <>
          <UsageRightsModal
            open={modalOrTrayOptions?.id === 'manage-usage-rights'}
            items={modalOrTrayOptions?.items || []}
            onDismiss={setModalOrTrayOptions(null)}
          />
          <PermissionsModal
            open={modalOrTrayOptions?.id === 'permissions'}
            items={modalOrTrayOptions?.items || []}
            onDismiss={setModalOrTrayOptions(null)}
          />
        </>,
        document.body,
      ),
    [modalOrTrayOptions?.id, modalOrTrayOptions?.items, setModalOrTrayOptions],
  )

  const tableCaption = I18n.t(
    'Files and Folders: sorted by %{sortColumn} in %{sortDirection} order',
    {
      sortColumn: columnHeaders.find(header => header.id === sort.by)?.title || sort.by,
      sortDirection: sort.direction === SortOrder.ASCENDING ? 'ascending' : 'descending',
    },
  )

  const showDrop = userCanEditFilesForContext && !isLoading && !searchString && !isStacked
  const isEmpty = rows.length === 0 && !isLoading
  const isAccessRestricted = getFilesEnv().userFileAccessRestricted

  return (
    <>
      {renderModals()}
      <Flex direction="column">
        <DragAndDropWrapper
          enabled={!isEmpty && showDrop && !!currentFolder && !isAccessRestricted}
          minHeight={420}
          currentFolder={currentFolder!}
          contextId={contextId}
          contextType={pluralizeContextTypeString(contextType)}
        >
          <Table
            id="files-table"
            caption={tableCaption}
            hover={true}
            layout={isStacked ? 'stacked' : 'fixed'}
            data-testid="files-table"
          >
            <Table.Head
              renderSortLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}
            >
              <Table.Row>
                {renderTableHead(
                  size,
                  allRowsSelected,
                  someRowsSelected,
                  selectionHandler.toggleSelectAll,
                  isStacked,
                  filteredColumns,
                  sort,
                  handleColumnHeaderClick,
                  selectAllRef,
                )}
              </Table.Row>
            </Table.Head>
            <Table.Body>
              <TableBody
                rows={rows}
                columnHeaders={filteredColumns}
                selectedRows={selectedRows}
                size={size}
                isStacked={isStacked}
                toggleRowSelection={selectionHandler.toggleSelection}
                selectRange={selectionHandler.selectRange}
                userCanEditFilesForContext={userCanEditFilesForContext}
                userCanDeleteFilesForContext={userCanDeleteFilesForContext}
                userCanRestrictFilesForContext={userCanRestrictFilesForContext}
                usageRightsRequiredForContext={usageRightsRequiredForContext}
                setModalOrTrayOptions={setModalOrTrayOptions}
                onPreviewFile={onPreviewFile}
              />
            </Table.Body>
          </Table>
        </DragAndDropWrapper>
        <SubTableContent
          isLoading={isLoading}
          isEmpty={isEmpty}
          searchString={searchString}
          showDrop={showDrop}
          handleFileDropRef={handleFileDropRef}
        />
        <Alert
          liveRegion={() => document.getElementById('flash_screenreader_holder')!}
          liveRegionPoliteness="polite"
          screenReaderOnly
          data-testid="sort-announcement"
        >
          {I18n.t('Sorted by %{sortColumn} in %{sortDirection} order', {
            sortColumn: columnHeaders.find(header => header.id === sort.by)?.title || sort.by,
            sortDirection: sort.direction === SortOrder.ASCENDING ? 'ascending' : 'descending',
          })}
        </Alert>
        {searchString && rows.length > 0 && (
          <Alert
            liveRegion={() => document.getElementById('flash_screenreader_holder')!}
            liveRegionPoliteness="assertive"
            screenReaderOnly
            data-testid="search-announcement"
          >
            {I18n.t(
              'file_search_count',
              {one: 'One result found', other: '%{count} results found'},
              {count: rows.length},
            )}
          </Alert>
        )}
      </Flex>
    </>
  )
}

export default FileFolderTable
