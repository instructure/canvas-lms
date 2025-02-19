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

import React, {useCallback, useContext, useEffect, useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useQuery, queryClient} from '@canvas/query'
import {type File, type Folder} from '../../../interfaces/File'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {parseLinkHeader} from '../../../utils/apiUtils'
import {getUniqueId} from '../../../utils/fileFolderUtils'
import SubTableContent from './SubTableContent'
import ActionMenuButton from './ActionMenuButton'
import NameLink from './NameLink'
import PublishIconButton from './PublishIconButton'
import RightsIconButton from './RightsIconButton'
import renderTableHead from './RenderTableHead'
import renderTableBody from './RenderTableBody'
import BulkActionButtons from './BulkActionButtons'
import Breadcrumbs from './Breadcrumbs'
import CurrentUploads from '../FilesHeader/CurrentUploads'
import {View} from '@instructure/ui-view'
import {FileManagementContext} from '../Contexts'
import {FileFolderWrapper, FilesCollectionEvent} from '../../../utils/fileFolderWrappers'
import BlueprintIconButton from './BlueprintIconButton'
import {Alert} from '@instructure/ui-alerts'
import CurrentDownloads from '../FilesHeader/CurrentDownloads'

const I18n = createI18nScope('files_v2')

const fetchFilesAndFolders = async (
  url: string,
  onLoadingStatusChange: (arg0: boolean) => void,
) => {
  onLoadingStatusChange(true)
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error('Failed to fetch files and folders')
  }
  const links = parseLinkHeader(response.headers.get('Link'))
  const rows = await response.json()
  return {rows, links}
}

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
    id: 'published',
    title: I18n.t('Published'),
    textAlign: 'center',
    width: undefined,
  },
  {id: 'actions', title: '', textAlign: 'center', width: '3em'},
]

setColumnWidths(columnHeaders)

const columnRenderers: {
  [key: string]: ({
    row,
    isStacked,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    usageRightsRequiredForContext,
    size,
    isSelected,
    toggleSelect,
  }: {
    row: File | Folder
    isStacked: boolean
    userCanEditFilesForContext: boolean
    userCanDeleteFilesForContext: boolean
    usageRightsRequiredForContext: boolean
    size: 'small' | 'medium' | 'large'
    isSelected: boolean
    toggleSelect: () => void
  }) => React.ReactNode
} = {
  name: ({row, isStacked}) => <NameLink isStacked={isStacked} item={row} />,
  created_at: ({row}) => <FriendlyDatetime dateTime={row.created_at} />,
  updated_at: ({row}) => (
    <div style={{padding: '0 0.5em'}}>
      <FriendlyDatetime dateTime={row.updated_at} />
    </div>
  ),
  modified_by: ({row}) =>
    'user' in row && row.user?.display_name ? (
      <Link isWithinText={false} href={row.user.html_url}>
        <div style={{textOverflow: 'ellipsis', overflow: 'hidden'}}>
          <Text>{row.user.display_name}</Text>
        </div>
      </Link>
    ) : null,
  size: ({row}) =>
    'size' in row ? <Text>{friendlyBytes(row.size)}</Text> : <Text>{I18n.t('--')}</Text>,
  rights: ({row, userCanEditFilesForContext, usageRightsRequiredForContext}) =>
    row.folder_id && usageRightsRequiredForContext ? (
      <RightsIconButton
        usageRights={row.usage_rights}
        userCanEditFilesForContext={userCanEditFilesForContext}
      />
    ) : null,
  blueprint: ({row}) => <BlueprintIconButton item={row} />,
  published: ({row, userCanEditFilesForContext}) => (
    <PublishIconButton item={row} userCanEditFilesForContext={userCanEditFilesForContext} />
  ),
  actions: ({
    row,
    size,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
    usageRightsRequiredForContext,
  }) => (
    <ActionMenuButton
      size={size}
      userCanEditFilesForContext={userCanEditFilesForContext}
      userCanDeleteFilesForContext={userCanDeleteFilesForContext}
      usageRightsRequiredForContext={usageRightsRequiredForContext}
      row={row}
    />
  ),
}

export interface FileFolderTableProps {
  size: 'small' | 'medium' | 'large'
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  currentUrl: string
  folderBreadcrumbs: Folder[]
  onPaginationLinkChange: (links: Record<string, string>) => void
  onLoadingStatusChange: (isLoading: boolean) => void
  onSortChange: (sortBy: string, sortDir: 'asc' | 'desc') => void
  searchString?: string
}

const FileFolderTable = ({
  size,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  usageRightsRequiredForContext,
  currentUrl,
  folderBreadcrumbs,
  onPaginationLinkChange,
  onLoadingStatusChange,
  onSortChange,
  searchString = '',
}: FileFolderTableProps) => {
  const {currentFolder} = useContext(FileManagementContext)
  const isStacked = size !== 'large'
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())
  const [selectionAnnouncement, setSelectionAnnouncement] = useState<string>('')

  const [sortColumn, setSortColumn] = useState<string>('name')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc' | 'none'>('asc')

  const {data, error, isLoading, isFetching} = useQuery({
    queryKey: ['files', currentUrl],
    queryFn: () => {
      setSelectedRows(new Set())
      if (searchString.length === 1) {
        return Promise.resolve({rows: [], links: {}})
      }
      return fetchFilesAndFolders(currentUrl, onLoadingStatusChange)
    },
    staleTime: 0,
    onSuccess: ({links}) => {
      onPaginationLinkChange(links)
    },
    onSettled: result => {
      if (result) {
        const foldersAndFiles = result.rows.map((row: File | Folder) => new FileFolderWrapper(row))
        currentFolder?.files.set(foldersAndFiles)
      }
      onLoadingStatusChange(false)
    },
  })

  useEffect(() => {
    const listener = (event: FilesCollectionEvent) => {
      if (['add', 'remove', 'refetch'].includes(event))
        queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    }
    currentFolder?.addListener(listener)

    return () => currentFolder?.removeListener(listener)
  }, [currentFolder])

  if (error) {
    showFlashError(I18n.t('Failed to fetch files and folders'))
  }

  const rows: (File | Folder)[] = useMemo(
    () => (!isFetching && data?.rows && data.rows.length > 0 ? data.rows : []),
    [data?.rows, isFetching],
  )

  const toggleRowSelection = useCallback(
    (rowId: string) => {
      setSelectedRows(prev => {
        const newSet = new Set(prev)
        if (newSet.has(rowId)) {
          newSet.delete(rowId)
        } else {
          newSet.add(rowId)
        }
        setSelectionAnnouncement(
          I18n.t('%{selected} of %{total} selected', {
            selected: newSet.size,
            total: rows.length,
          }),
        )

        return newSet
      })
    },
    [rows?.length],
  )

  const toggleSelectAll = useCallback(() => {
    if (selectedRows.size === rows.length) {
      setSelectedRows(new Set()) // Unselect all
      setSelectionAnnouncement(
        I18n.t('%{selected} of %{total} selected', {
          selected: 0,
          total: rows.length,
        }),
      )
    } else {
      setSelectedRows(new Set(rows.map(row => getUniqueId(row)))) // Select all
      setSelectionAnnouncement(
        I18n.t('%{selected} of %{total} selected', {
          selected: rows.length,
          total: rows.length,
        }),
      )
    }
  }, [rows, selectedRows.size])

  const handleColumnHeaderClick = useCallback(
    (columnId: string) => {
      const newDir = columnId === sortColumn ? (sortDirection === 'asc' ? 'desc' : 'asc') : 'asc'
      const newCol = columnId
      setSortColumn(newCol)
      setSortDirection(newDir)
      onSortChange(newCol, newDir)
    },
    [onSortChange, sortColumn, sortDirection],
  )

  const allRowsSelected = rows.length != 0 && selectedRows.size === rows.length
  const someRowsSelected = selectedRows.size > 0 && !allRowsSelected
  const filteredColumns = columnHeaders.filter(column => {
    switch (column.id) {
      case 'rights':
        return usageRightsRequiredForContext
      case 'blueprint':
        return !!ENV.BLUEPRINT_COURSES_DATA
      default:
        return true
    }
  })

  const renderTableActionsHead = useCallback(() => {
    const direction = size === 'small' ? 'column' : 'row'
    return (
      <Flex gap="small" margin="0 0 medium" direction={direction}>
        <Flex.Item padding="xx-small" shouldShrink={true} shouldGrow={true}>
          <Breadcrumbs folders={folderBreadcrumbs} size={size} search={searchString} />
        </Flex.Item>

        <Flex.Item padding="xx-small">
          <BulkActionButtons
            size={size}
            selectedRows={selectedRows}
            rows={rows}
            totalRows={rows.length}
            userCanEditFilesForContext={userCanEditFilesForContext}
            userCanDeleteFilesForContext={userCanDeleteFilesForContext}
          />
        </Flex.Item>
      </Flex>
    )
  }, [
    size,
    folderBreadcrumbs,
    searchString,
    selectedRows,
    rows,
    userCanEditFilesForContext,
    userCanDeleteFilesForContext,
  ])

  const tableCaption = I18n.t(
    'Files and Folders: sorted by %{sortColumn} in %{sortDirection} order',
    {
      sortColumn: columnHeaders.find(header => header.id === sortColumn)?.title || sortColumn,
      sortDirection: sortDirection === 'asc' ? 'ascending' : 'descending',
    },
  )

  return (
    <>
      {renderTableActionsHead()}
      <View display="block" margin="0 0 medium">
        <CurrentUploads />
        <CurrentDownloads rows={rows} />
      </View>
      <Table caption={tableCaption} hover={true} layout={isStacked ? 'stacked' : 'fixed'}>
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
              sortColumn,
              sortDirection,
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
            usageRightsRequiredForContext,
          )}
        </Table.Body>
      </Table>
      <SubTableContent
        isLoading={isLoading || isFetching}
        isEmpty={rows.length === 0 && !isFetching}
        searchString={searchString}
      />
      {selectionAnnouncement && (
        <Alert
          liveRegion={() => document.getElementById('flash_screenreader_holder')!}
          liveRegionPoliteness="polite"
          screenReaderOnly
          data-testid="selection-announcement"
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
          sortColumn: columnHeaders.find(header => header.id === sortColumn)?.title || sortColumn,
          sortDirection: sortDirection === 'asc' ? 'ascending' : 'descending',
        })}
      </Alert>
    </>
  )
}

export default FileFolderTable
