/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState, useEffect, useCallback} from 'react'
import moment from 'moment'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import tz from '@canvas/timezone'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {unfudgeDateForProfileTimezone} from '@canvas/datetime/date-functions'
import doFetchApi from '@canvas/do-fetch-api-effect'
import InfiniteScroll from '@canvas/infinite-scroll'
import PageViewRow from './PageViewRow'

const I18n = useI18nScope('PageViews')

const SIZE = 50

export const PageViews = ({userID}) => {
  const getCSVURL = useCallback(
    date => {
      const baseCSVURL = `/users/${userID}/page_views.csv`
      return date
        ? baseCSVURL +
            '?start_time=' +
            unfudgeDateForProfileTimezone(date).toISOString() +
            '&' +
            'end_time=' +
            moment(unfudgeDateForProfileTimezone(date)).add(1, 'days').toISOString()
        : baseCSVURL
    },
    [userID]
  )

  const [jsonData, setPageViewResults] = useState([])
  const [queryDate, updateQueryDate] = useState('')
  const [error, setError] = useState('')
  const [csvURLLink, setCSVURLLink] = useState(getCSVURL(''))
  const [page, setPage] = useState('first')
  const [nextPage, setNextPage] = useState('')
  const [hasMore, setHasMore] = useState(false)
  const [scrollContainer, setScrollContainer] = useState(null)

  const formatDate = date => {
    return tz.format(date, 'date.formats.medium')
  }

  useEffect(() => {
    if (error)
      <Alert
        liveRegion={() => document.getElementById('aria_alerts')}
        liveRegionPoliteness="assertive"
        screenReaderOnly
      >
        {error}
      </Alert>
  }, [error])

  useEffect(() => {
    setCSVURLLink(getCSVURL(queryDate))
  }, [getCSVURL, queryDate])

  const onSuccessApi = data => {
    if (data.link.next) {
      setNextPage(data.link.next.page)
    }

    setPageViewResults(currentJsonData => {
      setHasMore(data.json.length === SIZE)
      return currentJsonData.concat(data.json)
    })
  }
  useEffect(() => {
    const params = {
      start_time: `${queryDate ? unfudgeDateForProfileTimezone(queryDate).toISOString() : ''}`,
      end_time: `${
        queryDate
          ? moment(unfudgeDateForProfileTimezone(queryDate)).add(1, 'days').toISOString()
          : ''
      }`,
      per_page: SIZE,
      page
    }
    if (page === 'first') {
      delete params.page
    }
    doFetchApi({
      path: `/api/v1/users/${userID}/page_views`,
      params
    })
      .then(onSuccessApi)
      .catch(() => {
        setError('Error Fetching PageViews')
      })
  }, [queryDate, page, userID])

  const updateData = date => {
    setPageViewResults([])
    updateQueryDate(date)
    setPage('first')
  }

  const loadMore = () => {
    setPage(nextPage)
  }

  return (
    <>
      <div style={{overflowx: 'hidden', overflowy: 'hidden'}}>
        <Flex
          key="pageviews_datefilter"
          direction="column"
          margin="none none small"
          align="start"
          overflowY="hidden"
          overflowX="hidden"
          height="570px"
        >
          <Flex.Item
            textAlign="start"
            padding="xx-small"
            height="50px"
            overflowY="hidden"
            overflowX="hidden"
          >
            <Text weight="bold">{I18n.t('Filter by date')}</Text>
          </Flex.Item>
          <Flex.Item
            padding="x-small"
            height="50px"
            shouldShrink
            overflowY="hidden"
            overflowX="hidden"
          >
            <Flex overflowY="hidden" overflowX="hidden">
              <Flex.Item>
                <CanvasDateInput
                  dataTestid="inputQueryDate"
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Filter by date')}</ScreenReaderContent>
                  }
                  onSelectedDateChange={updateData}
                  formatDate={formatDate}
                  withRunningValue
                />
              </Flex.Item>
              <Flex.Item padding="x-small">
                <Link id="page_views_csv_link" data-testid="page_views_csv_link" href={csvURLLink}>
                  {I18n.t('Download Page Views CSV')}
                </Link>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item height="20px" />
          <Flex.Item
            key="page_views_table"
            padding="x-small"
            height="450px"
            overflowY="auto"
            id="scrollContainer"
            data-testid="scrollContainer"
            elementRef={setScrollContainer}
          >
            <InfiniteScroll
              pageStart={0}
              loadMore={loadMore}
              hasMore={hasMore}
              scrollContainer={scrollContainer}
              loader={
                <Spinner
                  id="paginatedView-loading"
                  renderTitle={I18n.t('Loading')}
                  size="small"
                  margin="0 0 0 medium"
                />
              }
            >
              <Table layout="fixed" caption="Page View Results" user-id={userID}>
                <Table.Head>
                  <Table.Row key="0">
                    <Table.ColHeader id="URL">
                      {I18n.t('#page_views.table.headers.url', 'URL')}
                    </Table.ColHeader>
                    <Table.ColHeader id="Date" width="175px">
                      {(I18n.t('#page_views.table.headers.date'), 'Date')}
                    </Table.ColHeader>
                    <Table.ColHeader id="Paticipated" width="115px" textAlign="start">
                      {(I18n.t('#page_views.table.headers.participated'), 'Participated')}
                    </Table.ColHeader>
                    <Table.ColHeader id="Time" width="60px" textAlign="start">
                      {(I18n.t('#page_views.table.headers.time'), 'Time')}
                    </Table.ColHeader>
                    <Table.ColHeader id="Agent" width="125px">
                      {(I18n.t('#page_views.table.headers.user_agent'), 'User Agent')}
                    </Table.ColHeader>
                  </Table.Row>
                </Table.Head>
                <Table.Body id="page_view_results">
                  {jsonData.map((element, index) => (
                    <PageViewRow displayName="Row" rowData={element} key={index.toString()} />
                  ))}
                </Table.Body>
              </Table>
            </InfiniteScroll>
          </Flex.Item>
        </Flex>
      </div>
    </>
  )
}
