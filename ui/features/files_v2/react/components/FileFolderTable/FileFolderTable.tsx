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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {TruncateText} from '@instructure/ui-truncate-text'

import {type File, type Folder} from '../../../interfaces/File'
import SubTableContent from './SubTableContent'
import ActionMenuButton from './ActionMenuButton'
import NameLink from './NameLink'
import PublishIconButton from './PublishIconButton'
import RightsIconButton from './RightsIconButton'

const I18n = useI18nScope('files_v2')

interface ColumnHeader {
  id: string
  title: string
  textAlign: 'start' | 'center' | 'end'
  width?: string
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
    userCanEditFilesForContext: boolean
  ) => React.ReactNode
} = {
  name: (row, isStacked) => <NameLink isStacked={isStacked} item={row} />,
  created: row => <FriendlyDatetime dateTime={row.created_at} />,
  lastModified: row => <FriendlyDatetime dateTime={row.updated_at} />,
  modifiedBy: row =>
    'user' in row ? (
      <Link
        isWithinText={false}
        href={row.user.html_url}
      >
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
  isLoading: boolean
  userCanEditFilesForContext: boolean
  rows?: (File | Folder)[]
}

const FileFolderTable = ({
  size,
  isLoading,
  userCanEditFilesForContext,
  rows = [],
}: FileFolderTableProps) => {
  const isStacked = size !== 'large'

  return (
    <>
      <Table
        caption={I18n.t('Files and Folders')}
        hover={true}
        layout={isStacked ? 'stacked' : 'fixed'}
      >
        <Table.Head>
          <Table.Row>
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
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {rows.map(row => (
            <Table.Row key={row.id} data-testid="table-row">
              {columnHeaders.map(column => (
                <Table.Cell key={column.id} textAlign={isStacked ? undefined : column.textAlign}>
                  {columnRenderers[column.id](row, isStacked, userCanEditFilesForContext)}
                </Table.Cell>
              ))}
            </Table.Row>
          ))}
        </Table.Body>
      </Table>
      <SubTableContent isLoading={isLoading} isEmpty={rows.length === 0} />
    </>
  )
}

export default FileFolderTable
