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
import {File, Folder} from 'features/files_v2/interfaces/File'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {getUniqueId} from '../../../utils/fileFolderUtils'

// Need to render in this manner to satisfy TypeScript and make sure headers are rendered in stacked view
const renderTableBody = (
  rows: (File | Folder)[],
  columnHeaders: ColumnHeader[],
  selectedRows: Set<string>,
  size: 'small' | 'medium' | 'large',
  isStacked: boolean,
  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  columnRenderers: Record<string, Function>,
  toggleRowSelection: (id: string) => void,
  userCanEditFilesForContext: boolean,
  userCanDeleteFilesForContext: boolean,
  usageRightsRequiredForContext: boolean,
) => {
  return rows.map(row => {
    const isSelected = selectedRows.has(getUniqueId(row))
    const rowHead = [
      <Table.RowHeader key="select">
        <Checkbox
          label=""
          scope="row"
          size={size}
          checked={isSelected}
          onChange={() => toggleRowSelection(getUniqueId(row))}
          data-testid="row-select-checkbox"
        />
      </Table.RowHeader>,
      ...columnHeaders.map(column => (
        <Table.Cell
          scope="row"
          key={column.id}
          textAlign={isStacked ? undefined : column.textAlign}
        >
          {columnRenderers[column.id]({
            row: row,
            isStacked: isStacked,
            userCanEditFilesForContext: userCanEditFilesForContext,
            userCanDeleteFilesForContext: userCanDeleteFilesForContext,
            usageRightsRequiredForContext: usageRightsRequiredForContext,
            size: size,
            isSelected: isSelected,
            toggleSelect: () => toggleRowSelection(getUniqueId(row)),
          })}
        </Table.Cell>
      )),
    ]
    return (
      <Table.Row
        key={getUniqueId(row)}
        data-testid="table-row"
        themeOverride={isSelected ? {borderColor: 'brand'} : undefined}
      >
        {...rowHead}
      </Table.Row>
    )
  })
}

export default renderTableBody
