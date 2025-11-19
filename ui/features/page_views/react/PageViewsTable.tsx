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

import React, {useState, useEffect} from 'react'
import {useScope as i18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useInfiniteQuery, type QueryFunctionContext, type InfiniteData} from '@tanstack/react-query'
import {
  type APIPageView,
  type PageView,
  formatURL,
  formatInteractionTime,
  formatParticipated,
  formatUserAgent,
} from './utils'
import {Pagination} from '@instructure/ui-pagination'
import {Flex} from '@instructure/ui-flex'
import ConfusedPanda from '@canvas/images/ConfusedPanda.svg'

export interface PageViewsTableProps {
  userId: string
  startDate?: Date
  endDate?: Date
  onEmpty?: () => void
  pageSize?: number
}

type APIQueryParams = {
  page: string
  per_page: string
  start_time?: string
  end_time?: string
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

  const [visiblePage, setVisiblePage] = useState(0)
  const visiblePageSize = props.pageSize ?? 10

  async function fetchPageViews({
    pageParam = '1',
  }: QueryFunctionContext<[string, string, Date?, Date?], string>): Promise<{
    views: Array<PageView>
    nextPage: string | null
  }> {
    const params: APIQueryParams = {
      page: typeof pageParam === 'string' ? pageParam : '1',
      per_page: '256',
    }
    if (props.startDate) {
      if (!props.endDate) throw new RangeError('endDate must be set if startDate is set')
      params.start_time = props.startDate.toISOString()
      params.end_time = props.endDate.toISOString()
    }
    const path = `/api/v1/users/${props.userId}/page_views`
    const {json, link} = await doFetchApi<Array<APIPageView>>({path, params})
    if (typeof json === 'undefined') return {views: [], nextPage: null}
    const views: Array<PageView> = json.map(v => ({
      id: v.id,
      url: formatURL(v),
      createdAt: new Date(v.created_at),
      participated: formatParticipated(v),
      interactionSeconds: formatInteractionTime(v),
      rawUserAgentString: v.user_agent,
      userAgent: formatUserAgent(v),
    }))
    const nextPage = link?.next ? link.next.page : null
    if (pageParam === '1') setVisiblePage(0) // reset to first page when changing filters
    return {views, nextPage}
  }

  const {data, fetchNextPage, isFetching, isFetchingNextPage, hasNextPage, isSuccess, error} =
    useInfiniteQuery<
      {views: Array<PageView>; nextPage: string | null},
      Error,
      InfiniteData<{views: Array<PageView>; nextPage: string | null}>,
      [string, string, Date?, Date?],
      string
    >({
      queryKey: ['page_views', props.userId, props.startDate, props.endDate],
      queryFn: fetchPageViews,
      staleTime: 10 * 60 * 1000, // 10 minutes
      getNextPageParam: lastPage => lastPage.nextPage,
      initialPageParam: '1',
    })

  // Automatically fetch next page when user has viewed all available data
  useEffect(() => {
    if (data && isSuccess && hasNextPage && !isFetchingNextPage) {
      // Calculate total unique views across all pages
      const uniqueViews: Record<string, PageView> = {}
      data.pages.forEach(page => {
        page.views.forEach(view => {
          uniqueViews[view.id] = view
        })
      })
      const totalViews = Object.keys(uniqueViews).length

      // Check if we need more data to fill the current visible page
      const hasNextVisiblePage = (visiblePage + 1) * visiblePageSize < totalViews

      if (!hasNextVisiblePage) {
        void fetchNextPage()
      }
    }
  }, [
    data,
    isSuccess,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    visiblePage,
    visiblePageSize,
  ])

  if (isFetching && !isFetchingNextPage) return <Spinner renderTitle={I18n.t('Loading')} />

  if (!isSuccess) {
    // if we have an error, then the query failed, display an alert
    if (error) {
      let errorText: string
      const {response} = error as any // a response means an error from doFetchApi
      if (typeof response !== 'undefined')
        errorText = `API error: ${response.status} ${response.statusText}, fetching ${response.url}`
      else {
        const err = error as Error
        errorText = `Error formatting table: ${err.name}, ${err.message}`
      }
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
    // if there is no error, then the query is still loading / retrying / something else
    // all we know is that an API fetch is not in progress but we still don't have data yet
    else return <Spinner renderTitle={I18n.t('Loading')} />
  }

  function pageNumberRenderer(page: number) {
    if (page < totalVisiblePages) return page
    if (hasNextPage) return page + '+'
    return page
  }

  const uniqueViews: Record<string, PageView> = {}

  data.pages.forEach(page => {
    page.views.forEach(view => {
      uniqueViews[view.id] = view
    })
  })
  const viewKeys = Object.keys(uniqueViews)
  const visibleKeys = viewKeys.slice(
    visiblePage * visiblePageSize,
    (visiblePage + 1) * visiblePageSize,
  )
  const totalVisiblePages = Math.ceil(viewKeys.length / visiblePageSize)

  if (viewKeys.length === 0 && props.onEmpty) {
    // We bubble this up so the parent can hide any sub filtering controls, which would again return nothing
    props.onEmpty()
    return <EmptyState />
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
              {visibleKeys.map(id => {
                const v = uniqueViews[id]
                return (
                  <Table.Row data-testid="page-view-row" key={id}>
                    <Table.Cell>
                      <Text size="small">{v.url}</Text>
                    </Table.Cell>
                    <Table.Cell>{formatDate(v.createdAt)}</Table.Cell>
                    <Table.Cell textAlign="center">{v.participated}</Table.Cell>
                    <Table.Cell textAlign="end">{v.interactionSeconds}</Table.Cell>
                    <Table.Cell>
                      <UserAgentCell view={v} />
                    </Table.Cell>
                  </Table.Row>
                )
              })}
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
          currentPage={visiblePage + 1}
          totalPageNumber={totalVisiblePages}
          onPageChange={nextPage => setVisiblePage(nextPage - 1)}
          withFirstAndLastButton
          renderPageIndicator={page => pageNumberRenderer(page)}
        />
      </Flex.Item>

      {isFetchingNextPage && (
        <Flex.Item>
          <Spinner size="small" renderTitle={I18n.t('Loading')} />
        </Flex.Item>
      )}
    </Flex>
  )
}
