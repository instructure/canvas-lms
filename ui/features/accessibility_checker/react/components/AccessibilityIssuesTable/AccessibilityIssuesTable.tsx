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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table, TableColHeaderProps} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {ContentItem} from '../../types'
import {AccessibilityIssuesTableRow} from './AccessibilityIssuesTableRow'

const I18n = createI18nScope('accessibility_checker')

export type TableSortState = {
  sortId?: string
  sortDirection?: TableColHeaderProps['sortDirection']
}

type Props = {
  isLoading?: boolean
  error?: string | null
  onRowClick?: (item: ContentItem) => void
  onSortRequest?: (sortId?: string, sortDirection?: TableColHeaderProps['sortDirection']) => void
  tableData?: ContentItem[]
  tableSortState?: TableSortState
}

const headerThemeOverride: TableColHeaderProps['themeOverride'] = (
  _componentTheme,
  currentTheme,
) => ({
  padding: '0.875rem 0.75rem', // Make column header height 3rem
})

const renderTableData = (
  tableData?: ContentItem[],
  error?: string | null,
  onRowClick?: (item: ContentItem) => void,
) => {
  if (error) return

  return (
    <>
      {tableData?.length === 0 || !tableData ? (
        <Table.Row data-testid="no-issues-row">
          <Table.Cell colSpan={5} textAlign="center">
            <Text color="secondary">{I18n.t('No accessibility issues found')}</Text>
          </Table.Cell>
        </Table.Row>
      ) : (
        tableData.map(item => (
          <AccessibilityIssuesTableRow key={`${item.id}`} item={item} onRowClick={onRowClick} />
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

export const AccessibilityIssuesTable = ({
  isLoading = false,
  error,
  onRowClick,
  onSortRequest,
  tableData,
  tableSortState,
}: Props) => {
  const handleSort = useCallback(
    (_event: React.SyntheticEvent, param: {id: TableColHeaderProps['id']}) => {
      let sortDirection: TableSortState['sortDirection'] = 'ascending'

      if (tableSortState?.sortId === param.id) {
        // If the same column is clicked, toggle the sort direction
        sortDirection =
          tableSortState?.sortDirection === 'ascending'
            ? 'descending'
            : tableSortState?.sortDirection === 'descending'
              ? 'none'
              : 'ascending'
      }
      const newState: Partial<TableSortState> = {
        sortId: param.id,
        sortDirection,
      }

      if (onSortRequest) {
        onSortRequest(newState.sortId, newState.sortDirection)
      }
    },
    [tableSortState, onSortRequest],
  )

  const getCurrentSortDirection = (
    id: TableColHeaderProps['id'],
  ): 'ascending' | 'descending' | 'none' => {
    if (tableSortState?.sortId === id) {
      return tableSortState?.sortDirection || 'none'
    }
    return 'none'
  }

  return (
    <View as="div" margin="medium 0 0 0" borderWidth="small" borderRadius="medium">
      <Table
        caption={
          <ScreenReaderContent>{I18n.t('Content with accessibility issues')}</ScreenReaderContent>
        }
        hover
        data-testid="accessibility-issues-table"
      >
        <Table.Head
          renderSortLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}
        >
          <Table.Row>
            <Table.ColHeader
              id="artifact-name-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('artifact-name-header')}
              themeOverride={headerThemeOverride}
            >
              <Text weight="bold">{I18n.t('Artifact Name')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="issues-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('issues-header')}
              themeOverride={headerThemeOverride}
            >
              <Text weight="bold">{I18n.t('Issues')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="artifact-type-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('artifact-type-header')}
              themeOverride={headerThemeOverride}
            >
              <Text weight="bold">{I18n.t('Artifact Type')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="state-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('state-header')}
              themeOverride={headerThemeOverride}
            >
              <Text weight="bold">{I18n.t('State')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="last-edited-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('last-edited-header')}
              themeOverride={headerThemeOverride}
            >
              <Text weight="bold">{I18n.t('Last edited')}</Text>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>

        <Table.Body>
          {error && (
            <Table.Row data-testid="error-row">
              <Table.Cell colSpan={5} textAlign="center">
                <Alert variant="error">{error}</Alert>
              </Table.Cell>
            </Table.Row>
          )}
          {isLoading && (
            <Table.Row data-testid="loading-row">
              <Table.Cell colSpan={5} textAlign="center">
                {renderLoading()}
              </Table.Cell>
            </Table.Row>
          )}
          {renderTableData(tableData, error, onRowClick)}
        </Table.Body>
      </Table>
    </View>
  )
}
