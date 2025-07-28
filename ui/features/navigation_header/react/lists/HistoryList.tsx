/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useEffect, useState} from 'react'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {formatTimeAgoDate, formatTimeAgoTitle} from '@canvas/enhanced-user-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import {useInfiniteQuery} from '@tanstack/react-query'
import type {QueryFunctionContext} from '@tanstack/react-query'

const I18n = createI18nScope('new_nav')

const fetchHistory = async (context: QueryFunctionContext<string[], string>) => {
  const {pageParam = '/api/v1/users/self/history'} = context
  const {json, link} = await doFetchApi({path: pageParam})
  const nextPage = link?.next ? link.next.url : null
  return {json, nextPage}
}

export default function HistoryList() {
  const [lastItem, setLastItem] = useState<Element | null>(null)

  const {data, fetchNextPage, isLoading, hasNextPage, error, isFetchingNextPage} = useInfiniteQuery(
    {
      queryKey: ['history'],
      queryFn: fetchHistory,
      getNextPageParam: lastPage => lastPage.nextPage || undefined,
      initialPageParam: '/api/v1/users/self/history',
    },
  )

  // @ts-expect-error
  const combineHistoryEntries = pages => {
    if (pages != null) {
      // combine all entries into one array
      // @ts-expect-error
      const allEntries = pages.reduce((accumulator, page) => {
        return [...accumulator, ...page.json]
      }, [])
      // iterate over all entries and combine based on asset_code
      // @ts-expect-error
      const historyEntries = allEntries.reduce((accumulator, historyItem) => {
        // @ts-expect-error
        const alreadyAdded = accumulator.some(entry => historyItem.asset_code === entry.asset_code)
        if (!alreadyAdded) {
          accumulator.push(historyItem)
        }
        return accumulator
      }, [])
      return historyEntries
    }
    return []
  }

  useEffect(() => {
    if (lastItem && hasNextPage) {
      const observer = new IntersectionObserver(
        entries => {
          if (entries[0].isIntersecting) {
            // reset observer and fetch
            observer.disconnect()
            setLastItem(null)
            fetchNextPage()
          }
        },
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.4,
        },
      )
      observer.observe(lastItem)
    }
  }, [fetchNextPage, hasNextPage, lastItem])

  if (error) {
    return <Alert variant="error">{I18n.t('Failed to retrieve history')}</Alert>
  } else if (isLoading || data == null) {
    return <Spinner size="small" renderTitle={I18n.t('Loading')} />
  } else {
    const historyEntries = combineHistoryEntries(data.pages)
    return (
      <>
        <List isUnstyled={true} margin="small 0" itemSpacing="small">
          {/* @ts-expect-error */}
          {historyEntries.map((entry, index) => {
            return (
              <List.Item key={entry.asset_code}>
                <Flex>
                  <Flex.Item align="start" padding="none x-small none none">
                    <i className={entry.asset_icon} aria-hidden="true" />
                  </Flex.Item>
                  <Flex.Item shouldGrow={true}>
                    <Link
                      href={entry.visited_url}
                      aria-label={`${entry.asset_name}, ${entry.asset_readable_category}`}
                    >
                      {entry.asset_name}
                    </Link>
                    <Text as="div" transform="uppercase" size="x-small" lineHeight="condensed">
                      {entry.context_name}
                    </Text>
                    <Text
                      data-testid={`${entry.asset_code}_time_ago`}
                      as="div"
                      size="x-small"
                      color="secondary"
                      lineHeight="condensed"
                      className="time_ago_date"
                      data-timestamp={entry.visited_at}
                      title={formatTimeAgoTitle(entry.visited_at)}
                    >
                      {formatTimeAgoDate(entry.visited_at)}
                    </Text>
                  </Flex.Item>
                </Flex>
              </List.Item>
            )
          })}
        </List>
        {hasNextPage && !isFetchingNextPage && (
          <div
            ref={el => {
              setLastItem(el)
            }}
          />
        )}
      </>
    )
  }
}
