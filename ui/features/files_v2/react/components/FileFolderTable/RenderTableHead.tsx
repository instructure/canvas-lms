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

import React, {Ref} from 'react'
import {Table} from '@instructure/ui-table'
import {Checkbox} from '@instructure/ui-checkbox'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {Sort} from '../../hooks/useGetPaginatedFiles'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ColumnHeaderText} from './ColumnHeaderText'

const I18n = createI18nScope('files_v2')

const mapSortDirection = (sortDirection: Sort['direction']) => {
  switch (sortDirection) {
    case 'asc':
      return 'ascending'
    case 'desc':
      return 'descending'
    default:
      return 'none'
  }
}

const renderTableHead = (
  size: 'small' | 'medium' | 'large',
  allRowsSelected: boolean,
  someRowsSelected: boolean,
  toggleSelectAll: () => void,
  isStacked: boolean,
  columnHeaders: ColumnHeader[],
  sort: Sort,
  handleSortChange: (column: string) => void,
  selectAllRef?: Ref<Checkbox>,
) => {
  return [
    <Table.ColHeader
      scope="col"
      key="select"
      id="select"
      textAlign="center"
      width="2.5em"
      data-testid="select"
    >
      <Checkbox
        label={<ScreenReaderContent>{I18n.t('Select all files and folders')}</ScreenReaderContent>}
        size={size}
        checked={allRowsSelected}
        indeterminate={someRowsSelected}
        onChange={toggleSelectAll}
        data-testid="select-all-checkbox"
        ref={selectAllRef}
      />
    </Table.ColHeader>,
    ...columnHeaders.map(columnHeader => (
      <Table.ColHeader
        scope="col"
        key={columnHeader.id}
        id={columnHeader.id}
        textAlign={isStacked ? undefined : columnHeader.textAlign}
        width={columnHeader.width}
        data-testid={columnHeader.id}
        onRequestSort={
          columnHeader.isSortable ? () => handleSortChange(columnHeader.id) : undefined
        }
        sortDirection={sort.by === columnHeader.id ? mapSortDirection(sort.direction) : 'none'}
        stackedSortByLabel={columnHeader.title}
      >
        {/* If we render null in ColumnHeaderText, we get ":" as the header for Actions in stacked view */}
        {columnHeader.title && (
          <ColumnHeaderText columnHeader={columnHeader} isStacked={isStacked} />
        )}
      </Table.ColHeader>
    )),
  ]
}

export default renderTableHead
