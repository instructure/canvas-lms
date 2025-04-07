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

import React, {useCallback, useEffect, useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {queryClient} from '@canvas/query'
import {type File, type Folder} from '../../../interfaces/File'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {getUniqueId} from '../../../utils/fileFolderUtils'
import SubTableContent from './SubTableContent'
import ActionMenuButton from './ActionMenuButton'
import NameLink from './NameLink'
import PublishIconButton from './PublishIconButton'
import RightsIconButton from './RightsIconButton'
import renderTableHead from './RenderTableHead'
import renderTableBody from './RenderTableBody'
import {useFileManagement} from '../Contexts'
import {FilesCollectionEvent} from '../../../utils/fileFolderWrappers'
import BlueprintIconButton from './BlueprintIconButton'
import {Alert} from '@instructure/ui-alerts'
import UsageRightsModal from './UsageRightsModal'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import FileTableUpload from './FileTableUpload'
import {UpdatedAtDate} from './UpdatedAtDate'
import {ModifiedByLink} from './ModifiedByLink'
import PermissionsModal from './PermissionsModal'
import {Sort} from '../../hooks/useGetPaginatedFiles'
import {createPortal} from 'react-dom'

const I18n = createI18nScope('files_v2')

const MIN_HEIGHT = 450

const setColumnWidths = (headers: ColumnHeader[]) => {
  // Use a temporary div to calculate the width of each column
  const temp = document.createElement('div')
  temp.style.position = 'absolute'
  temp.style.visibility = 'hidden'
  temp.style.whiteSpace = 'nowrap'
  temp.style.left = '-9999px'
  temp.style.fontFamily = getComputedStyle(document.body).fontFamily
  temp.style.fontSize = getComputedStyle(document.body).fontSize
  temp.style.fontWeight = 'bold'
  document.body.appendChild(temp)

  const fontSizeInPx = parseFloat(temp.style.fontSize)

  headers.forEach(header => {
    if (header.width) return // some headers have fixed widths
    temp.textContent = header.title
    const width = temp.getBoundingClientRect().width
    const widthInEms = width / fontSizeInPx
    const padding = 1.5
    header.width = `${Math.round(Math.max(3, widthInEms + padding) * 100) / 100}em`
  })
  document.body.removeChild(temp)
}

const columnHeaders: ColumnHeader[] = [
  {id: 'name', title: I18n.t('Name'), textAlign: 'start', width: '12.5em'},
  {
    id: 'created_at',
    title: I18n.t('Created'),
    textAlign: 'start',
    width: undefined,
  },
  {
    id: 'updated_at',
    title: I18n.t('Last Modified'),
    textAlign: 'start',
    width: undefined,
  },
  {
    id: 'modified_by',
    title: I18n.t('Modified By'),
    textAlign: 'start',
    width: undefined,
  },
  {id: 'size', title: I18n.t('Size'), textAlign: 'start', width: ''},
  {
    id: 'rights',
    title: I18n.t('Rights'),
    textAlign: 'center',
    width: undefined,
  },
  {
    id: 'blueprint',
    title: I18n.t('Blueprint'),
    textAlign: 'center',
    width: undefined,
  },
  {
    id: 'permissions',
    title: I18n.t('Status'),
    textAlign: 'center',
    width: undefined,
  },
  {id: 'actions', title: '', textAlign: 'center', width: '3em'},
]

setColumnWidths(columnHeaders)

const columnRenderers: {
  [key: string]: ({
    row,
    rows,
    isStacked,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    userCanRestrictFilesForContext,
    usageRightsRequiredForContext,
    size,
    isSelected,
    toggleSelect,
    setModalOrTrayOptions,
  }: {
    row: File | Folder
    rows: (File | Folder)[]
    isStacked: boolean
    userCanEditFilesForContext: boolean
    userCanDeleteFilesForContext: boolean
    userCanRestrictFilesForContext: boolean
    usageRightsRequiredForContext: boolean
    size: 'small' | 'medium' | 'large'
    isSelected: boolean
    toggleSelect: () => void
    setModalOrTrayOptions: (modalOrTray: ModalOrTrayOptions | null) => () => void
  }) => React.ReactNode
} = {
  name: ({row, rows, isStacked}) => <NameLink isStacked={isStacked} item={row} collection={rows} />,
  created_at: ({row}) => <FriendlyDatetime dateTime={row.created_at} includeScreenReaderContent={false}/>,
  updated_at: ({row, isStacked}) => (
    <UpdatedAtDate updatedAt={row.updated_at} isStacked={isStacked} />
  ),
  modified_by: ({row, isStacked}) =>
    'user' in row && row.user?.display_name ? (
      <ModifiedByLink
        htmlUrl={row.user.html_url}
        displayName={row.user.display_name}
        isStacked={isStacked}
      />
    ) : null,
  size: ({row}) =>
    'size' in row ? <Text>{friendlyBytes(row.size)}</Text> : <Text>{I18n.t('--')}</Text>,
  rights: ({
    row,
    userCanEditFilesForContext,
    usageRightsRequiredForContext,
    setModalOrTrayOptions,
  }) =>
    row.folder_id && usageRightsRequiredForContext ? (
      <RightsIconButton
        usageRights={row.usage_rights}
        userCanEditFilesForContext={userCanEditFilesForContext}
        onClick={setModalOrTrayOptions({id: 'manage-usage-rights', items: [row]})}
      />
    ) : null,
  blueprint: ({row}) => <BlueprintIconButton item={row} />,
  permissions: ({row, userCanRestrictFilesForContext, setModalOrTrayOptions}) => (
    <PublishIconButton
      item={row}
      userCanRestrictFilesForContext={userCanRestrictFilesForContext}
      onClick={setModalOrTrayOptions({id: 'permissions', items: [row]})}
    />
  ),
  actions: ({
    row,
    size,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    userCanRestrictFilesForContext,
    usageRightsRequiredForContext,
  }) => (
    <ActionMenuButton
      size={size}
      userCanEditFilesForContext={userCanEditFilesForContext}
      userCanDeleteFilesForContext={userCanDeleteFilesForContext}
      userCanRestrictFilesForContext={userCanRestrictFilesForContext}
      usageRightsRequiredForContext={usageRightsRequiredForContext}
      row={row}
    />
  ),
}

const getSelectionScreenReaderText = (selected: number, total: number) => {
  return I18n.t('%{selected} of %{total} selected', {
    selected,
    total,
  })
}

export type ModalOrTrayOptions = {
  id: 'manage-usage-rights' | 'permissions'
  items: (File | Folder)[]
}

export interface FileFolderTableProps {
  size: 'small' | 'medium' | 'large'
  rows: (File | Folder)[]
  isLoading: boolean
  contextType: string
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  userCanRestrictFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  sort: Sort
  onSortChange: (sort: Sort) => void
  searchString?: string
  selectedRows: Set<string>
  setSelectedRows: React.Dispatch<React.SetStateAction<Set<string>>>
}

const FileFolderTable = ({
  size,
  rows,
  isLoading,
  contextType,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  userCanRestrictFilesForContext,
  usageRightsRequiredForContext,
  sort,
  onSortChange,
  searchString = '',
  selectedRows,
  setSelectedRows,
}: FileFolderTableProps) => {
  const {currentFolder} = useFileManagement()
  const isStacked = size !== 'large'

  const [selectionAnnouncement, setSelectionAnnouncement] = useState<string>(() => {
    return getSelectionScreenReaderText(selectedRows.size, rows.length)
  })
  const [modalOrTrayOptions, _setModalOrTrayOptions] = useState<ModalOrTrayOptions | null>(null)

  const [isDragging, setIsDragging] = useState(false)
  const [directoryMinHeight, setDirectoryMinHeight] = useState('auto')

  const filesDirectoryRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const listener = (event: FilesCollectionEvent) => {
      if (['add', 'remove', 'refetch'].includes(event))
        queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    }
    currentFolder?.addListener(listener)

    return () => currentFolder?.removeListener(listener)
  }, [currentFolder])

  const setModalOrTrayOptions = useCallback(
    (options: ModalOrTrayOptions | null) => () => _setModalOrTrayOptions(options),
    [],
  )

  const toggleRowSelection = useCallback(
    (rowId: string) => {
      const newSet = new Set(selectedRows)
      if (newSet.has(rowId)) {
        newSet.delete(rowId)
      } else {
        newSet.add(rowId)
      }
      setSelectedRows(newSet)
      setSelectionAnnouncement(getSelectionScreenReaderText(newSet.size, rows.length))
    },
    [selectedRows, rows.length],
  )

  const toggleSelectAll = useCallback(() => {
    if (selectedRows.size === rows.length) {
      setSelectedRows(new Set()) // Unselect all
      setSelectionAnnouncement(getSelectionScreenReaderText(0, rows.length))
    } else {
      setSelectedRows(new Set(rows.map(row => getUniqueId(row)))) // Select all
      setSelectionAnnouncement(getSelectionScreenReaderText(rows.length, rows.length))
    }
  }, [rows, selectedRows.size])

  enum SortOrder {
    ASCENDING = 'asc',
    DESCENDING = 'desc',
  }

  const handleColumnHeaderClick = useCallback(
    (columnId: string) => {
      const newCol = columnId
      const newDirection =
        columnId === sort.by
          ? sort.direction === SortOrder.ASCENDING
            ? SortOrder.DESCENDING
            : SortOrder.ASCENDING
          : SortOrder.ASCENDING
      onSortChange({by: newCol, direction: newDirection})
    },
    [onSortChange, sort.by, sort.direction],
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
    () => createPortal(
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

  const showDrop = !isLoading && !searchString && !isStacked

  const handleDragEnter = (e: React.DragEvent<HTMLDivElement>) => {
    if (e.dataTransfer?.types.includes('Files')) {
      e.preventDefault()
      if (!isDragging && showDrop) {
        if (filesDirectoryRef.current && filesDirectoryRef.current.offsetHeight < MIN_HEIGHT) {
          setDirectoryMinHeight(MIN_HEIGHT + 'px')
        }
        setIsDragging(true)
      }
      return false
    } else {
      return true
    }
  }

  const handleDragLeave = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    if (filesDirectoryRef.current) {
      const rect = filesDirectoryRef.current.getBoundingClientRect()
      if (
        rect &&
        (e.clientY < rect.top ||
          e.clientY >= rect.bottom ||
          e.clientX < rect.left ||
          e.clientX >= rect.right)
      ) {
        setIsDragging(false)
        setDirectoryMinHeight('auto')
      }
    }
  }

  const handleDropState = () => {
    setIsDragging(false)
    setDirectoryMinHeight('auto')
  }

  const handleDrop = (
    accepted: ArrayLike<DataTransferItem | globalThis.File>,
    _rejected: ArrayLike<DataTransferItem | globalThis.File>,
    e: React.DragEvent<Element>,
  ) => {
    e.preventDefault()
    e.stopPropagation()
    handleDropState()
    FileOptionsCollection.setFolder(currentFolder)
    FileOptionsCollection.setOptionsFromFiles(accepted, true)
  }

  return (
    <>
      {renderModals()}
      <Flex direction='column'>
        <div
          data-testid="files-directory"
          ref={filesDirectoryRef}
          style={{minHeight: rows.length === 0 && showDrop ? MIN_HEIGHT : directoryMinHeight}}
          className="files_directory"
          onDragEnter={e => handleDragEnter(e as React.DragEvent<HTMLDivElement>)}
          onDragLeave={e => handleDragLeave(e as React.DragEvent<HTMLDivElement>)}
          onDragOver={e => e.preventDefault()}
          onDrop={_e => handleDropState()}
        >
          <Table
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
                  toggleSelectAll,
                  isStacked,
                  filteredColumns,
                  sort,
                  handleColumnHeaderClick,
                )}
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {renderTableBody(
                rows,
                filteredColumns,
                selectedRows,
                size,
                isStacked,
                columnRenderers,
                toggleRowSelection,
                userCanEditFilesForContext,
                userCanDeleteFilesForContext,
                userCanRestrictFilesForContext,
                usageRightsRequiredForContext,
                setModalOrTrayOptions,
              )}
              {userCanEditFilesForContext && showDrop && (
                <Table.Row data-upload>
                  <Table.Cell>
                    <FileTableUpload
                      currentFolder={currentFolder!}
                      isDragging={isDragging}
                      handleDrop={handleDrop}
                    />
                  </Table.Cell>
                </Table.Row>
              )}
            </Table.Body>
          </Table>
        </div>
        <SubTableContent
          isLoading={isLoading}
          isEmpty={rows.length === 0 && !isLoading}
          searchString={searchString}
        />
        {selectionAnnouncement && (
          <Alert
            liveRegion={() => document.getElementById('flash_screenreader_holder')!}
            liveRegionPoliteness="polite"
            screenReaderOnly
          >
            {selectionAnnouncement}
          </Alert>
        )}
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
