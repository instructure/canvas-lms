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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useEffect, useCallback} from 'react'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {formatTimeAgoDate, formatTimeAgoTitle} from '@canvas/enhanced-user-content'
import {useInfiniteQuery} from '@tanstack/react-query'

const I18n = useI18nScope('new_nav')

export default function HistoryList() {
  const fetchHistory = useCallback(
    async ({pageParam = '/api/v1/users/self/history?per_page=100'}) => {
      const res = await fetch(pageParam)
      const data = await res.json()
      const linkHeader = res.headers.get('link')
      const nextPage = linkHeader
        ? linkHeader
            .split(',')
            .find(s => s.includes('rel="next"'))
            ?.match(/<([^>]+)>/)?.[1]
        : undefined
      return {data, nextPage}
    },
    []
  )

  const {data, fetchNextPage, isFetching, hasNextPage} = useInfiniteQuery({
    queryKey: ['history'],
    queryFn: fetchHistory,
    getNextPageParam: lastPage => lastPage.nextPage,
  })

  const combinedHistoryEntries = data
    ? data.pages.reduce(
        (acc, page) => {
          const seenAssetCodes = new Set(acc.data.map(entry => entry.asset_code))
          const newEntries = page.data.filter(entry => {
            if (!seenAssetCodes.has(entry.asset_code)) {
              seenAssetCodes.add(entry.asset_code)
              return true
            }
            return false
          })
          acc.data = [...acc.data, ...newEntries]
          acc.nextPage = page.nextPage
          return acc
        },
        {data: [], nextPage: null}
      )
    : {data: [], nextPage: null}

  useEffect(() => {
    if (hasNextPage && !isFetching) {
      fetchNextPage()
    }
  }, [hasNextPage, isFetching, fetchNextPage])

  return (
    <>
      <List isUnstyled={true} margin="small 0" itemSpacing="small">
        {combinedHistoryEntries.data.length === 0 && isFetching && (
          <List.Item>
            <Spinner size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
        {combinedHistoryEntries.data.map(entry => (
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
        ))}
      </List>
    </>
  )
}
