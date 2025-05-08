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
import {getCheckboxLabel, getUniqueId} from '../../../utils/fileFolderUtils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ModalOrTrayOptions} from '../../../interfaces/FileFolderTable'
import {columnRenderers} from './FileFolderTableUtils'
// Need to render in this manner to satisfy TypeScript and make sure headers are rendered in stacked view
const renderTableBody = (
  rows: (File | Folder)[],
  columnHeaders: ColumnHeader[],
  selectedRows: Set<string>,
  size: 'small' | 'medium' | 'large',
  isStacked: boolean,
  toggleRowSelection: (id: string) => void,
  userCanEditFilesForContext: boolean,
  userCanDeleteFilesForContext: boolean,
  userCanRestrictFilesForContext: boolean,
  usageRightsRequiredForContext: boolean,
  setModalOrTrayOptions: (modalOrTray: ModalOrTrayOptions | null) => () => void,
) => {
  return rows.map((row, index) => {
    const isSelected = selectedRows.has(getUniqueId(row))
    const rowHead = [
      <Table.RowHeader key="select">
        <Checkbox
          label={<ScreenReaderContent>{getCheckboxLabel(row)}</ScreenReaderContent>}
          scope="row"
          size={size}
          checked={isSelected}
          onChange={() => toggleRowSelection(getUniqueId(row))}
          data-testid="row-select-checkbox"
        />
      </Table.RowHeader>,
      ...columnHeaders.map(column => (
        <Table.Cell key={column.id} textAlign={isStacked ? undefined : column.textAlign}>
          {columnRenderers[column.id]({
            row: row,
            rows: rows,
            isStacked: isStacked,
            userCanEditFilesForContext: userCanEditFilesForContext,
            userCanDeleteFilesForContext: userCanDeleteFilesForContext,
            userCanRestrictFilesForContext: userCanRestrictFilesForContext,
            usageRightsRequiredForContext: usageRightsRequiredForContext,
            size: size,
            isSelected: isSelected,
            toggleSelect: () => toggleRowSelection(getUniqueId(row)),
            setModalOrTrayOptions,
            rowIndex: index,
          })}
        </Table.Cell>
      )),
    ]
    return (
      <Table.Row key={getUniqueId(row)} data-testid="table-row">
        {...rowHead}
      </Table.Row>
    )
  })
}

export default renderTableBody
