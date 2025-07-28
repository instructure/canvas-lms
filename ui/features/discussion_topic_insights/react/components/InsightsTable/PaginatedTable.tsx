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
import React, {useEffect, useState} from 'react'
import {Pagination} from '@instructure/ui-pagination'
import {Flex} from '@instructure/ui-flex'
import {BaseTableProps} from './SimpleTable'
import SortableTable from './SortableTable'
import useInsightStore from '../../hooks/useInsightStore'

export type PaginatedTableProps = BaseTableProps & {
  perPage: number
}

const PaginatedTable: React.FC<PaginatedTableProps> = ({caption, headers, rows, perPage}) => {
  const [page, setPage] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  const isFilteredTable = useInsightStore(state => state.isFilteredTable)
  const setIsFilteredTable = useInsightStore(state => state.setIsFilteredTable)

  useEffect(() => {
    setIsFilteredTable(false)
    setPage(0)
    setCurrentPage(1)
  }, [isFilteredTable, setIsFilteredTable])

  const pageCount = perPage && Math.ceil(rows.length / perPage)

  const handlePageChange = (nextPage: number) => {
    setCurrentPage(nextPage)
    setPage(nextPage - 1)
  }

  return (
    <Flex width="100%" direction="column" wrap="wrap" alignItems="center">
      <SortableTable
        caption={caption}
        headers={headers}
        rows={rows}
        perPage={perPage}
        page={page}
      />
      {pageCount > 1 && (
        <Flex.Item>
          <Pagination
            as="nav"
            variant="input"
            labelNext="Next Page"
            labelPrev="Previous Page"
            margin="small"
            currentPage={currentPage}
            onPageChange={handlePageChange}
            totalPageNumber={pageCount}
          />
        </Flex.Item>
      )}
    </Flex>
  )
}

export default PaginatedTable
