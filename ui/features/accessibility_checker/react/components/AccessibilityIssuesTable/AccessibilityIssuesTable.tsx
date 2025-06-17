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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'
import {Table, TableColHeaderProps} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {ContentItem} from '../../types'
import {IssueCell} from './IssueCell'

const I18n = createI18nScope('accessibility_checker')

export type TableSortState = {
  sortId?: string
  sortDirection?: TableColHeaderProps['sortDirection']
}

type Props = {
  isLoading?: boolean
  onRowClick?: (item: ContentItem) => void
  onSortRequest?: (sortId?: string, sortDirection?: TableColHeaderProps['sortDirection']) => void
  tableData?: ContentItem[]
  tableSortState?: TableSortState
}

export const AccessibilityIssuesTable = ({
  // isLoading, - TODO implement loading states
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

  const handleRowClick = useCallback(
    (item: ContentItem) => {
      if (onRowClick) {
        onRowClick(item)
      }
    },
    [onRowClick],
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
              id="name-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('name-header')}
            >
              <Text weight="bold">{I18n.t('Content Name')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="issues-header"
              textAlign="center"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('issues-header')}
            >
              <Text weight="bold">{I18n.t('Issues')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="content-type-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('content-type-header')}
            >
              <Text weight="bold">{I18n.t('Content Type')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="state-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('state-header')}
            >
              <Text weight="bold">{I18n.t('State')}</Text>
            </Table.ColHeader>

            <Table.ColHeader
              id="updated-header"
              onRequestSort={handleSort}
              sortDirection={getCurrentSortDirection('updated-header')}
            >
              <Text weight="bold">{I18n.t('Last updated')}</Text>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {tableData?.length === 0 || !tableData ? (
            <Table.Row data-testid="no-issues-row">
              <Table.Cell colSpan={5} textAlign="center">
                <Text color="secondary">{I18n.t('No accessibility issues found')}</Text>
              </Table.Cell>
            </Table.Row>
          ) : (
            tableData.map(item => (
              <Table.Row key={`${item.type}-${item.id}`} data-testid={`issue-row-${item.id}`}>
                <Table.Cell>
                  <Flex alignItems="center">
                    <Flex.Item margin="0 0 0 x-small">
                      <a href={item.url}>{item.title}</a>
                    </Flex.Item>
                  </Flex>
                </Table.Cell>
                <Table.Cell textAlign="center">
                  <IssueCell item={item} onClick={handleRowClick} />
                </Table.Cell>
                <Table.Cell>{item.type}</Table.Cell>
                <Table.Cell>
                  <Flex alignItems="center">
                    {item.published ? (
                      <>
                        <Flex.Item margin="medium">
                          <IconPublishSolid color="success" />
                        </Flex.Item>
                        <Flex.Item>
                          <Text>{I18n.t('Published')}</Text>
                        </Flex.Item>
                      </>
                    ) : (
                      <>
                        <Flex.Item margin="medium">
                          <IconUnpublishedSolid color="secondary" />
                        </Flex.Item>
                        <Flex.Item>
                          <Text>{I18n.t('Unpublished')}</Text>
                        </Flex.Item>
                      </>
                    )}
                  </Flex>
                </Table.Cell>
                <Table.Cell>
                  {item.updatedAt
                    ? new Intl.DateTimeFormat('en-US', {
                        year: 'numeric',
                        month: 'short',
                        day: '2-digit',
                      }).format(new Date(item.updatedAt))
                    : '-'}
                </Table.Cell>
              </Table.Row>
            ))
          )}
        </Table.Body>
      </Table>
    </View>
  )
}
