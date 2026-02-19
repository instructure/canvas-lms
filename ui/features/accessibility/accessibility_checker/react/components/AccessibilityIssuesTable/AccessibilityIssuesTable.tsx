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

import {useCallback} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Table, TableColHeaderProps} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {IssuesTableColumns, IssuesTableColumnHeaders} from '../../constants'
import {AccessibilityResourceScan} from '../../../../shared/react/types'
import {AccessibilityIssuesTableRow} from './AccessibilityIssuesTableRow'
import {
  useAccessibilityScansStore,
  TableSortState,
} from '../../../../shared/react/stores/AccessibilityScansStore'
import {useAccessibilityScansFetchUtils} from '../../../../shared/react/hooks/useAccessibilityScansFetchUtils'
import {useAccessibilityScansPolling} from '../../../../shared/react/hooks/useAccessibilityScansPolling'
import {responsiveQuerySizes} from '@canvas/breakpoints'

const I18n = createI18nScope('accessibility_checker')

const headerThemeOverride: TableColHeaderProps['themeOverride'] = _componentTheme => ({
  padding: '0.875rem 0.75rem', // Make column header height 3rem
})

const getNewTableSortState = (
  _event: React.SyntheticEvent,
  param: {id: TableColHeaderProps['id']},
  existingSortState?: TableSortState | null,
): TableSortState => {
  let sortDirection: TableSortState['sortDirection'] = ReverseOrderingFirst.includes(param.id)
    ? 'descending'
    : 'ascending'

  if (existingSortState?.sortId === param.id) {
    sortDirection = existingSortState?.sortDirection === 'ascending' ? 'descending' : 'ascending'
  }

  return {
    sortId: param.id,
    sortDirection,
  }
}

const renderTableData = (
  isMobile: boolean,
  scans?: AccessibilityResourceScan[] | null,
  error?: string | null,
  loading?: boolean,
) => {
  if (error || loading) return

  return (
    <>
      {scans?.length === 0 || !scans ? (
        <Table.Row data-testid="no-issues-row">
          <Table.Cell colSpan={6} textAlign="center">
            <Text color="secondary">{I18n.t('No accessibility issues found')}</Text>
          </Table.Cell>
        </Table.Row>
      ) : (
        scans.map(item => (
          <AccessibilityIssuesTableRow
            key={`${item.resourceType}-${item.id}`}
            item={item}
            isMobile={isMobile}
          />
        ))
      )}
    </>
  )
}

const renderLoading = () => {
  return (
    <Flex direction="column" alignItems="center" margin="small 0">
      <Flex.Item shouldGrow>
        <Spinner renderTitle="Loading accessibility issues" size="large" margin="none" />
      </Flex.Item>
      <Flex.Item>
        <PresentationContent>{I18n.t('Loading accessibility issues')}</PresentationContent>
      </Flex.Item>
    </Flex>
  )
}

// If these columns are sorted, a reverse cycle is more convenient
const ReverseOrderingFirst = [IssuesTableColumns.Issues, IssuesTableColumns.LastEdited]

export const AccessibilityIssuesTable = () => {
  const {doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary} =
    useAccessibilityScansFetchUtils()

  useAccessibilityScansPolling()

  const [error, loading, page, pageCount, accessibilityScans, tableSortState] =
    useAccessibilityScansStore(
      useShallow(state => [
        state.error,
        state.loading,
        state.page,
        state.pageCount,
        state.accessibilityScans,
        state.tableSortState,
      ]),
    )

  const handleSort = useCallback(
    (_event: React.SyntheticEvent, param: {id: TableColHeaderProps['id']}) => {
      const newState: Partial<TableSortState> = getNewTableSortState(_event, param, tableSortState)

      doFetchAccessibilityScanData({
        tableSortState: newState,
        page: 1,
      })
    },
    [tableSortState, doFetchAccessibilityScanData],
  )

  const getCurrentSortDirection = useCallback(
    (id: TableColHeaderProps['id']): 'ascending' | 'descending' | 'none' => {
      if (tableSortState?.sortId === id) {
        return tableSortState?.sortDirection || 'none'
      }
      return 'none'
    },
    [tableSortState],
  )

  const handlePageChange = useCallback(
    (nextPage: number) => {
      doFetchAccessibilityScanData({
        page: nextPage,
      })
      doFetchAccessibilityIssuesSummary({})
    },
    [doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary],
  )

  return (
    <Responsive
      query={responsiveQuerySizes({mobile: true, tablet: true, desktop: true})}
      props={{
        mobile: {isMobile: true},
        tablet: {isMobile: false},
        desktop: {isMobile: false},
      }}
    >
      {props => (
        <View width="100%">
          <View as="div" margin="medium 0 0 0" borderWidth="small" borderRadius="medium">
            <Table
              caption={
                <ScreenReaderContent>
                  {I18n.t('Resources with accessibility issues')}
                </ScreenReaderContent>
              }
              hover
              layout={props?.isMobile ? 'stacked' : 'auto'}
              data-testid="accessibility-issues-table"
            >
              <Table.Head
                renderSortLabel={<Flex padding="small small 0">{I18n.t('Sort by')}</Flex>}
              >
                <Table.Row>
                  {IssuesTableColumnHeaders.map(header => {
                    return (
                      <Table.ColHeader
                        key={header.id}
                        id={header.id}
                        onRequestSort={handleSort}
                        sortDirection={getCurrentSortDirection(header.id)}
                        themeOverride={headerThemeOverride}
                        stackedSortByLabel={header.name}
                      >
                        <Text weight="bold">{header.name}</Text>
                      </Table.ColHeader>
                    )
                  })}
                </Table.Row>
              </Table.Head>

              <Table.Body>
                {error && (
                  <Table.Row data-testid="error-row">
                    <Table.Cell colSpan={6} textAlign="center">
                      <Alert variant="error">{error}</Alert>
                    </Table.Cell>
                  </Table.Row>
                )}
                {loading && (
                  <Table.Row data-testid="loading-row">
                    <Table.Cell colSpan={6} textAlign="center">
                      {renderLoading()}
                    </Table.Cell>
                  </Table.Row>
                )}
                {renderTableData(props?.isMobile ?? false, accessibilityScans, error, loading)}
              </Table.Body>
            </Table>
          </View>
          {pageCount > 1 && (
            <Flex.Item>
              <Pagination
                data-testid={`accessibility-issues-table-pagination`}
                as="nav"
                variant="compact"
                labelNext={I18n.t('Next Page')}
                labelPrev={I18n.t('Previous Page')}
                margin="small"
                currentPage={page}
                onPageChange={handlePageChange}
                totalPageNumber={pageCount}
              />
            </Flex.Item>
          )}
        </View>
      )}
    </Responsive>
  )
}
