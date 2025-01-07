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

import React, {useState, useMemo, useContext} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {useQuery} from '@tanstack/react-query'

import {type File, type Folder} from '../../../interfaces/File'
import SubTableContent from './SubTableContent'
import ActionMenuButton from './ActionMenuButton'
import NameLink from './NameLink'
import PublishIconButton from './PublishIconButton'
import RightsIconButton from './RightsIconButton'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {FileManagementContext} from '../Contexts'

const I18n = createI18nScope('files_v2')

interface ColumnHeader {
  id: string
  title: string
  textAlign: 'start' | 'center' | 'end'
  width?: string
}

const fetchFilesAndFolders = async (folderId: string) => {
  const includeParams = ['user', 'usage_rights', 'enhanced_preview_url', 'context_asset_string']
  const url = `/api/v1/folders/${folderId}/all?include[]=${includeParams.join('&include[]=')}`
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error('Failed to fetch files and folders')
  }
  return response.json()
}

const columnHeaders: ColumnHeader[] = [
  {id: 'name', title: I18n.t('Name'), textAlign: 'start', width: '12.5em'},
  {id: 'created', title: I18n.t('Created'), textAlign: 'start', width: '6em'},
  {id: 'lastModified', title: I18n.t('Last Modified'), textAlign: 'start', width: '6em'},
  {id: 'modifiedBy', title: I18n.t('Modified By'), textAlign: 'start', width: '6em'},
  {id: 'size', title: I18n.t('Size'), textAlign: 'start', width: '4em'},
  {id: 'rights', title: I18n.t('Rights'), textAlign: 'center', width: '3.5em'},
  {id: 'published', title: I18n.t('Published'), textAlign: 'center', width: '4em'},
  {id: 'actions', title: '', textAlign: 'center', width: '3em'},
]

const columnRenderers: {
  [key: string]: (
    row: File | Folder,
    isStacked: boolean,
    userCanEditFilesForContext: boolean,
    size: 'small' | 'medium' | 'large',
    isSelected: boolean,
    toggleSelect: () => void,
  ) => React.ReactNode
} = {
  name: (row, isStacked) => <NameLink isStacked={isStacked} item={row} />,
  created: row => <FriendlyDatetime dateTime={row.created_at} />,
  lastModified: row => <FriendlyDatetime dateTime={row.updated_at} />,
  modifiedBy: row =>
    'user' in row && row.user?.display_name ? (
      <Link isWithinText={false} href={row.user.html_url}>
        <TruncateText>{row.user.display_name}</TruncateText>
      </Link>
    ) : null,
  size: row =>
    'size' in row ? <Text>{friendlyBytes(row.size)}</Text> : <Text>{I18n.t('--')}</Text>,
  rights: _row => <RightsIconButton />,
  published: (row, _isStacked, userCanEditFilesForContext) => (
    <PublishIconButton item={row} userCanEditFilesForContext={userCanEditFilesForContext} />
  ),
  actions: (_row, isStacked) => <ActionMenuButton isStacked={isStacked} />,
}

interface FileFolderTableProps {
  size: 'small' | 'medium' | 'large'
  userCanEditFilesForContext: boolean
}

const FileFolderTable = ({size, userCanEditFilesForContext}: FileFolderTableProps) => {
  const {folderId} = useContext(FileManagementContext)
  const isStacked = size !== 'large'
  const queryKey = useMemo(() => ['files', folderId], [folderId])

  const {data, error, isLoading, isFetching} = useQuery<(File | Folder)[], unknown>(queryKey, () =>
    fetchFilesAndFolders(folderId),
  )

  if (error) {
    showFlashError(I18n.t('Failed to fetch files and folders'))
  }

  const rows = !isFetching && data && data.length > 0 ? data : []

  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const toggleRowSelection = (rowId: string) => {
    setSelectedRows(prev => {
      const newSet = new Set(prev)
      if (newSet.has(rowId)) {
        newSet.delete(rowId)
      } else {
        newSet.add(rowId)
      }
      return newSet
    })
  }

  const toggleSelectAll = () => {
    if (selectedRows.size === rows.length) {
      setSelectedRows(new Set()) // Unselect all
    } else {
      setSelectedRows(new Set(rows.map(row => row.id))) // Select all
    }
  }
  const allRowsSelected = rows.length != 0 && selectedRows.size === rows.length
  const someRowsSelected = selectedRows.size > 0 && !allRowsSelected
  return (
    <>
      <Table
        caption={I18n.t('Files and Folders')}
        hover={true}
        layout={isStacked ? 'stacked' : 'fixed'}
      >
        <Table.Head>
          <Table.Row>
            <>
              <Table.ColHeader
                key="select"
                id="select"
                textAlign="center"
                width="1em"
                data-testid="select"
              >
                <Checkbox
                  label=""
                  size={size}
                  checked={allRowsSelected}
                  indeterminate={someRowsSelected}
                  onChange={toggleSelectAll}
                  data-testid="select-all-checkbox"
                />
              </Table.ColHeader>
              {columnHeaders.map(columnHeader => (
                <Table.ColHeader
                  key={columnHeader.id}
                  id={columnHeader.id}
                  textAlign={isStacked ? undefined : columnHeader.textAlign}
                  width={columnHeader.width}
                  data-testid={columnHeader.id}
                >
                  {columnHeader.title}
                </Table.ColHeader>
              ))}
            </>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {rows.map(row => {
            const isSelected = selectedRows.has(row.id)
            return (
              <Table.Row
                key={row.id}
                data-testid="table-row"
                themeOverride={isSelected ? {borderColor: 'brand'} : undefined}
              >
                <>
                  <Table.RowHeader>
                    <Checkbox
                      label=""
                      size={size}
                      checked={isSelected}
                      onChange={() => toggleRowSelection(row.id)}
                      data-testid="row-select-checkbox"
                    />
                  </Table.RowHeader>
                  {columnHeaders.map(column => (
                    <Table.Cell
                      key={column.id}
                      textAlign={isStacked ? undefined : column.textAlign}
                    >
                      {columnRenderers[column.id](
                        row,
                        isStacked,
                        userCanEditFilesForContext,
                        size,
                        isSelected,
                        () => toggleRowSelection(row.id),
                      )}
                    </Table.Cell>
                  ))}
                </>
              </Table.Row>
            )
          })}
        </Table.Body>
      </Table>
      <SubTableContent
        isLoading={isLoading || isFetching}
        isEmpty={rows.length === 0 && !isFetching}
      />
    </>
  )
}

export default FileFolderTable
