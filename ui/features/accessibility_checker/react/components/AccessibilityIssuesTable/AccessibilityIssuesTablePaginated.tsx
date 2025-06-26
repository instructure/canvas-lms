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
import {View} from '@instructure/ui-view'
import {AccessibilityIssuesTable} from './AccessibilityIssuesTable'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

interface AccessibilityIssueTablePaginatedProps {
  isLoading: boolean
  error?: string | null // Optional prop
  onRowClick: (item: any) => void // Adjust the type based on your data structure
  onSortRequest: (sortId?: string, sortDirection?: 'ascending' | 'descending' | 'none') => void
  tableData: Array<any> // Adjust the type based on your data structure
  tableSortState: object // Define a more specific type if possible
  perPage: number
}
const AccessibilityIssuesTablePaginated: React.FC<AccessibilityIssueTablePaginatedProps> = ({
  isLoading,
  error,
  onRowClick,
  onSortRequest,
  tableData,
  tableSortState,
  perPage,
}) => {
  const [page, setPage] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)

  useEffect(() => {
    setPage(0)
    setCurrentPage(1)
  }, [tableData])

  const pageCount = perPage && Math.ceil(tableData.length / perPage)

  const handlePageChange = (nextPage: number) => {
    setCurrentPage(nextPage)
    setPage(nextPage - 1)
  }

  const startIndex = page * perPage
  const endIndex = startIndex + perPage
  const paginatedData = tableData.slice(startIndex, endIndex)

  return (
    <View width="100%">
      <AccessibilityIssuesTable
        isLoading={isLoading}
        error={error}
        onRowClick={onRowClick}
        onSortRequest={onSortRequest}
        tableData={paginatedData}
        tableSortState={tableSortState}
      />
      {pageCount > 1 && (
        <Flex.Item>
          <Pagination
            data-testid={`accessibility-issues-table-pagination`}
            as="nav"
            variant="compact"
            labelNext={I18n.t('Next Page')}
            labelPrev={I18n.t('Previous Page')}
            margin="small"
            currentPage={currentPage}
            onPageChange={handlePageChange}
            totalPageNumber={pageCount}
          />
        </Flex.Item>
      )}
    </View>
  )
}

export default AccessibilityIssuesTablePaginated
