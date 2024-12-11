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

import React, {useRef} from 'react'
import {useScope as i18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useInfiniteQuery, type QueryFunctionContext} from '@tanstack/react-query'
import {
  type APIPageView,
  type PageView,
  formatURL,
  formatInteractionTime,
  formatParticipated,
  formatUserAgent,
} from './utils'

export interface PageViewsTableProps {
  userId: string
  startDate?: Date
  endDate?: Date
}

type APIQueryParams = {
  page: string
  per_page: string
  start_time?: string
  end_time?: string
}

const I18n = i18nScope('page_views')

export function PageViewsTable(props: PageViewsTableProps): React.JSX.Element {
  const observerRef = useRef<IntersectionObserver | null>(null)

  const formatDate = useDateTimeFormat('time.formats.short')
  async function fetchPageViews({
    pageParam = '1',
  }: QueryFunctionContext): Promise<{views: Array<PageView>; nextPage: string | null}> {
    const params: APIQueryParams = {
      page: pageParam,
      per_page: '50',
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
      userAgent: formatUserAgent(v),
    }))
    const nextPage = link?.next ? link.next.page : null
    return {views, nextPage}
  }

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        fetchNextPage()
        clearPageLoadTrigger()
      }
    })
    observerRef.current.observe(ref)
  }

  const {data, fetchNextPage, isFetching, isFetchingNextPage, hasNextPage, isSuccess} =
    useInfiniteQuery({
      queryKey: ['page_views', props.userId, props.startDate],
      queryFn: fetchPageViews,
      staleTime: 10 * 60 * 1000, // 10 minutes
      getNextPageParam: lastPage => lastPage.nextPage,
    })

  if (isFetching && !isFetchingNextPage) return <Spinner renderTitle={I18n.t('Loading')} />

  if (!isSuccess)
    return (
      <Alert variant="error" margin="small">
        {I18n.t('Could not retrieve page views')}
      </Alert>
    )

  const uniqueViews: Record<string, PageView> = {}
  data.pages.forEach(page => {
    page.views.forEach(view => {
      uniqueViews[view.id] = view
    })
  })
  const viewKeys = Object.keys(uniqueViews)
  const isTriggerRow = (row: number) => row === viewKeys.length - 1 && !!hasNextPage && !isFetching
  const setTrigger = (row: number) =>
    isTriggerRow(row) ? (ref: Element | null) => setPageLoadTrigger(ref) : undefined

  return (
    <>
      <Table caption={I18n.t('Page views for this user')}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="page-view-url">{I18n.t('URL')}</Table.ColHeader>
            <Table.ColHeader id="page-view-date">{I18n.t('Date')}</Table.ColHeader>
            <Table.ColHeader id="page-view-participated">{I18n.t('Participated')}</Table.ColHeader>
            <Table.ColHeader id="page-view-interaction-time">{I18n.t('Time')}</Table.ColHeader>
            <Table.ColHeader id="page-view-user-agent">{I18n.t('User Agent')}</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body data-testid="page-views-table-body">
          {viewKeys.map((id, idx) => {
            const v = uniqueViews[id]
            const url = (
              <Text size="small" elementRef={setTrigger(idx)}>
                {v.url}
              </Text>
            )
            return (
              <Table.Row data-testid="page-view-row" key={id}>
                <Table.Cell>{url}</Table.Cell>
                <Table.Cell>{formatDate(v.createdAt)}</Table.Cell>
                <Table.Cell textAlign="center">{v.participated}</Table.Cell>
                <Table.Cell>{v.interactionSeconds}</Table.Cell>
                <Table.Cell>{v.userAgent}</Table.Cell>
              </Table.Row>
            )
          })}
        </Table.Body>
      </Table>
      {isFetchingNextPage && <Spinner size="small" renderTitle={I18n.t('Loading')} />}
    </>
  )
}
