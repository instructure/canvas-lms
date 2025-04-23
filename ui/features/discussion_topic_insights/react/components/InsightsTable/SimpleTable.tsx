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
import React, {ReactNode} from 'react'
import {Table} from '@instructure/ui-table'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {getStatusByRelevance} from '../../utils'

const I18n = createI18nScope('discussion_insights')

export type Row = {
  relevance: string
  name: string
  notes: string
  date: string
  actions: ReactNode
}

export type Header = {
  id: keyof Row
  text: string
  width: string
  alignment: 'start' | 'center' | 'end'
  sortAble: boolean
}

export type BaseTableProps = {
  caption: string
  headers: Header[]
  rows: Row[]
}

export type SimpleTableProps = BaseTableProps & {
  onSort: (id: Header['id']) => void
  sortBy?: Header['id']
  ascending: boolean
}

const SimpleTable: React.FC<SimpleTableProps> = ({
  caption,
  headers,
  rows,
  onSort,
  sortBy,
  ascending,
}) => {
  const direction = ascending ? 'ascending' : 'descending'
  const translatedCaption = I18n.t('%{caption}: sorted by %{sortBy} in %{direction} order', {
    caption,
    sortBy,
    direction,
  })

  return (
    <Table caption={translatedCaption}>
      <Table.Head renderSortLabel={'Discussion Insights Table'}>
        <Table.Row>
          {headers.map(({id, text, width, alignment, sortAble}) => (
            <Table.ColHeader
              key={id}
              id={id}
              width={width}
              textAlign={alignment}
              onRequestSort={sortAble ? (_, {id}) => onSort(id as any) : undefined}
              sortDirection={id === sortBy ? direction : 'none'}
            >
              <Flex justifyItems={alignment}>{text}</Flex>
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {rows.map((row, index) => (
          <Table.Row key={index}>
            {headers.map(({id, alignment, width}) => (
              <Table.Cell key={id} textAlign={alignment} style={{width}}>
                {id === 'relevance' ? getStatusByRelevance(row[id]) : row[id]}
              </Table.Cell>
            ))}
          </Table.Row>
        ))}
      </Table.Body>
    </Table>
  )
}

export default SimpleTable
