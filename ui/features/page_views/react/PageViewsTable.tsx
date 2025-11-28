/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as i18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {Pagination} from '@instructure/ui-pagination'
import {Flex} from '@instructure/ui-flex'
import ConfusedPanda from '@canvas/images/ConfusedPanda.svg'
import type {PageView} from './utils'
import {useQueryPageViewsPaginated} from './hooks/useQueryPageViewsPaginated'

export interface PageViewsTableProps {
  userId: string
  startDate?: Date
  endDate?: Date
  onEmpty?: () => void
  pageSize?: number
}

const I18n = i18nScope('page_views')

function UserAgentCell({view}: {view: PageView}): React.JSX.Element {
  return (
    <Tooltip renderTip={view.rawUserAgentString} on={['hover', 'focus']}>
      {view.userAgent}
    </Tooltip>
  )
}

function EmptyState(): React.JSX.Element {
  return (
    <Flex
      direction="column"
      alignItems="center"
      gap="small"
      data-testid="page-views-empty-state"
      as={'div'}
    >
      <img
        src={ConfusedPanda}
        alt={I18n.t('Nothing in the last 30 days')}
        style={{maxWidth: '160px'}}
      />
      <Text size="large" weight="bold">
        {I18n.t('Nothing in the last 30 days')}
      </Text>
      <Text>
        {I18n.t(
          "This page shows only the past 30 days of history. It looks like there hasn't been anything recent to show.",
        )}
      </Text>
    </Flex>
  )
}

export function PageViewsTable(props: PageViewsTableProps): React.JSX.Element {
  const formatDate = useDateTimeFormat('time.formats.short')
  const pageSize = props.pageSize ?? 10

  // Single hook for paginated data management
  const {
    views,
    isFetching,
    isSuccess,
    error,
    currentPage,
    totalPages,
    hasReachedEnd,
    setCurrentPage,
  } = useQueryPageViewsPaginated({
    userId: props.userId,
    startDate: props.startDate,
    endDate: props.endDate,
    pageSize,
  })

  // Loading state
  if (isFetching) return <Spinner renderTitle={I18n.t('Loading')} />

  // Error handling
  if (!isSuccess) {
    if (error) {
      const {response} = error as any
      const errorText = response
        ? `API error: ${response.status} ${response.statusText}, fetching ${response.url}`
        : `Error formatting table: ${(error as Error).name}, ${(error as Error).message}`

      return (
        <Alert variant="error" margin="small">
          <p>
            <strong>{I18n.t('Could not retrieve page views')}</strong>
            <br />
            {errorText}
          </p>
        </Alert>
      )
    }
    return <Spinner renderTitle={I18n.t('Loading')} />
  }

  // Empty state
  if (views.length === 0 && props.onEmpty) {
    props.onEmpty()
    return <EmptyState />
  }

  // UI handlers for pagination
  const renderPageNumber = (page: number): string | number => {
    // Only show '+' for the last page if we haven't reached the end (more pages might exist)
    if (!hasReachedEnd && page === totalPages) return page + '+'
    return page
  }

  return (
    <Flex direction="column" gap="large">
      <Flex.Item>
        <div style={{minHeight: '21rem'}}>
          <Table caption={I18n.t('Page views for this user')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="page-view-url">{I18n.t('URL')}</Table.ColHeader>
                <Table.ColHeader id="page-view-date">{I18n.t('Date')}</Table.ColHeader>
                <Table.ColHeader id="page-view-participated" textAlign="center">
                  {I18n.t('Participated')}
                </Table.ColHeader>
                <Table.ColHeader id="page-view-interaction-time" textAlign="end">
                  {I18n.t('Time')}
                </Table.ColHeader>
                <Table.ColHeader id="page-view-user-agent">{I18n.t('User Agent')}</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body data-testid="page-views-table-body">
              {views.map(view => (
                <Table.Row data-testid="page-view-row" key={view.id}>
                  <Table.Cell>
                    <Text size="small">{view.url}</Text>
                  </Table.Cell>
                  <Table.Cell>{formatDate(view.createdAt)}</Table.Cell>
                  <Table.Cell textAlign="center">{view.participated}</Table.Cell>
                  <Table.Cell textAlign="end">{view.interactionSeconds}</Table.Cell>
                  <Table.Cell>
                    <UserAgentCell view={view} />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table.Body>
          </Table>
        </div>
      </Flex.Item>

      <Flex.Item>
        <Pagination
          as="nav"
          margin="small"
          variant="compact"
          labelNext={I18n.t('Next Page')}
          labelPrev={I18n.t('Previous Page')}
          currentPage={currentPage}
          totalPageNumber={totalPages}
          onPageChange={setCurrentPage}
          withFirstAndLastButton
          renderPageIndicator={renderPageNumber}
          data-testid="page-views-pagination"
          siblingCount={4}
        />
      </Flex.Item>
    </Flex>
  )
}
