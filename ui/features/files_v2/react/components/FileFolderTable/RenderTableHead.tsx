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
import {Table} from '@instructure/ui-table'
import {Checkbox} from '@instructure/ui-checkbox'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'

// TODO: when we know how to sort by modified_at and published, add them here.
const SORTABLE_COLUMNS = ['name', 'created_at', 'updated_at', 'size']

const isSortable = (column: string) => SORTABLE_COLUMNS.includes(column)

const mapSortDirection = (sortDirection: 'asc' | 'desc' | 'none') => {
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
  sortColumn: string | null,
  sortDirection: 'asc' | 'desc' | 'none',
  handleSortChange: (column: string) => void,
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
        label=""
        size={size}
        checked={allRowsSelected}
        indeterminate={someRowsSelected}
        onChange={toggleSelectAll}
        data-testid="select-all-checkbox"
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
          isSortable(columnHeader.id) ? () => handleSortChange(columnHeader.id) : undefined
        }
        sortDirection={sortColumn === columnHeader.id ? mapSortDirection(sortDirection) : 'none'}
        stackedSortByLabel={columnHeader.title}
      >
        {columnHeader.title}
      </Table.ColHeader>
    )),
  ]
}

export default renderTableHead
