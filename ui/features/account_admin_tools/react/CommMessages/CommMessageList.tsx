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

import React, {useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CommMessageDisplay from './CommMessageDisplay'
import {Alert} from '@instructure/ui-alerts'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {useInfiniteQuery, type QueryFunctionContext, type InfiniteData} from '@tanstack/react-query'
import type {CommMessage, MessagesQueryParams} from './types'

const I18n = createI18nScope('comm_messages')

type FetchReturn = {
  messages: CommMessage[]
  nextPage: string | null
}

type MessageQueryKey = ['comm_messages', string, string | undefined, string | undefined]

type APIQueryParams = {
  page: string
  per_page: string
  user_id: string
  start_time: string | undefined
  end_time: string | undefined
}

async function fetchCommMessages({
  queryKey,
  pageParam,
}: QueryFunctionContext<MessageQueryKey, string>): Promise<FetchReturn> {
  const [_, user_id, start_time, end_time] = queryKey
  const params: APIQueryParams = {
    page: pageParam,
    per_page: '10',
    user_id,
    start_time,
    end_time,
  }
  const path = '/api/v1/comm_messages'
  const {json, link} = await doFetchApi<Array<CommMessage>>({path, params})
  if (typeof json === 'undefined') return {messages: [], nextPage: null}
  const nextPage = link?.next ? link.next.page : null
  return {messages: json, nextPage}
}

export interface CommMessageListProps {
  query: MessagesQueryParams | null
}

export default function CommMessageList({query}: CommMessageListProps): JSX.Element {
  const dateFormat = useDateTimeFormat('time.formats.medium')
  const observerRef = useRef<IntersectionObserver | null>(null)
  const {userId, userName, startTime, endTime}: MessagesQueryParams = query ?? {
    userId: '',
    startTime: undefined,
    endTime: undefined,
    userName: '???',
  }
  const viewMessages: Record<string, CommMessage> = {}

  function byDateDescending(a: string, b: string) {
    const dateA = new Date(viewMessages[a].created_at)
    const dateB = new Date(viewMessages[b].created_at)
    if (dateA < dateB) return 1
    if (dateA > dateB) return -1
    return 0
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

  const {
    data,
    fetchNextPage,
    isFetching,
    isPending,
    isFetchingNextPage,
    hasNextPage,
    isSuccess,
    error,
  } = useInfiniteQuery<FetchReturn, Error, InfiniteData<FetchReturn>, MessageQueryKey, string>({
    queryKey: ['comm_messages', userId, startTime, endTime],
    queryFn: fetchCommMessages,
    getNextPageParam: lastPage => lastPage.nextPage,
    initialPageParam: '1',
    enabled: !!userId,
  })

  // If the query is disabled, we have nothing to show
  if (isPending && !isFetching) return <></>

  // If fetching for the first time, show a big spinner
  if (isFetching && !isFetchingNextPage) return <Spinner renderTitle={I18n.t('Loading')} />

  if (!isSuccess) {
    // if we have an error, then the query failed, display an alert
    if (error)
      return (
        <Alert variant="error" margin="small">
          <strong>{I18n.t('Error loading notifications')}</strong>
        </Alert>
      )
    // otherwise the query is still loading / retrying / something else
    return <Spinner renderTitle={I18n.t('Loading')} />
  }

  // occasionally the API returns duplicate results across pages, so we need
  // to coalesce those into one; this is the easiest way to do that.
  data.pages.forEach(page => {
    page.messages.forEach(message => {
      viewMessages[message.id] = message
    })
  })
  const keys = Object.keys(viewMessages).sort(byDateDescending)
  const isTriggerRow = (row: number) => row === keys.length - 1 && hasNextPage && !isFetching
  const setTrigger = (row: number) =>
    isTriggerRow(row) ? (ref: Element | null) => setPageLoadTrigger(ref) : undefined

  function headingText(): string {
    const start = startTime ? dateFormat(startTime) : I18n.t('the beginning of time')
    const end = endTime ? dateFormat(endTime) : I18n.t('now')
    return I18n.t('Displaying from *%{start}* to *%{end}*', {
      start,
      end,
      wrapper: ['<strong>$1</strong>'],
    })
  }

  return (
    <>
      <hr />
      <Heading variant="titleModule">
        {I18n.t('Notifications sent to %{userName}', {userName})}
      </Heading>
      <View margin="moduleElements none" as="div" data-testid="message-list-description">
        <Text
          variant="descriptionSection"
          dangerouslySetInnerHTML={{
            __html: headingText(),
          }}
        />
      </View>
      {keys.length > 0 ? (
        keys.map((id, idx) => (
          <div key={id} ref={setTrigger(idx)} data-testid={`message-result-${idx}`}>
            <CommMessageDisplay message={viewMessages[id]} />
          </div>
        ))
      ) : (
        <Alert
          data-testid="no-msgs-alert"
          hasShadow={false}
          variant="info"
          margin="moduleElements none"
        >
          {I18n.t('No messages found.')}
        </Alert>
      )}
      {isFetchingNextPage && <Spinner size="small" renderTitle={I18n.t('Loading more...')} />}
    </>
  )
}
