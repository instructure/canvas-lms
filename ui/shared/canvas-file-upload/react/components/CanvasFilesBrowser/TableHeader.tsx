/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {ColumnWidths} from '../../types'

const I18n = createI18nScope('canvas_file_upload')

interface TableHeaderProps {
  columnWidths: ColumnWidths
}

const TableHeader: React.FC<TableHeaderProps> = ({columnWidths}) => {
  const headerStyle = {
    borderBottom: `1px solid ${theme.colors.contrasts.grey1214}`,
  }

  const renderTableHeader = (name: string, size: string, key: number, grow: boolean) => (
    <Flex.Item padding="xx-small" size={size} key={key} shouldGrow={grow}>
      <Text size="small" weight="bold">
        {name}
      </Text>
    </Flex.Item>
  )

  const tableHeadings = [
    {name: I18n.t('Name'), size: columnWidths.nameAndThumbnailWidth, grow: true},
    {name: I18n.t('Date Created'), size: columnWidths.dateCreatedWidth, grow: false},
    {name: I18n.t('Date Modified'), size: columnWidths.dateModifiedWidth, grow: false},
    {name: I18n.t('Modified By'), size: columnWidths.modifiedByWidth, grow: false},
    {name: I18n.t('Size'), size: columnWidths.fileSizeWidth, grow: false},
    {name: I18n.t('Published'), size: columnWidths.publishedWidth, grow: false},
  ]

  return (
    <div style={headerStyle}>
      <Flex aria-hidden={true}>
        {tableHeadings.map((header, index) =>
          renderTableHeader(header.name, header.size, index, header.grow),
        )}
      </Flex>
    </div>
  )
}

export default TableHeader
