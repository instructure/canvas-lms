/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React, {useCallback, useReducer, useEffect, useMemo, useRef} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import JobsHeader from './components/JobsHeader'
import JobsTable from './components/JobsTable'
import GroupsTable from './components/GroupsTable'
import JobDetails from './components/JobDetails'
import SearchBox from './components/SearchBox'
import JobLookup from './components/JobLookup'
import SectionRefreshHeader from './components/SectionRefreshHeader'
import StrandManager from './components/StrandManager'
import TagThrottle from './components/TagThrottle'
import {jobsReducer, initialState} from './reducer'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import * as tz from '@canvas/datetime'
import moment from 'moment-timezone'

const I18n = useI18nScope('jobs_v2')
const AUTO_REFRESH_INTERVAL = 5000

export default function JobsIndex() {
  const [state, dispatch] = useReducer(jobsReducer, initialState())

  const jobListRef = useRef()
  const jobDetailsRef = useRef()

  const bucketCaptions = useMemo(() => {
    return {
      queued: I18n.t('Queued jobs'),
      running: I18n.t('Running jobs'),
      future: I18n.t('Future jobs'),
      failed: I18n.t('Failed jobs'),
    }
  }, [])

  const groupCaptions = useMemo(() => {
    return {
      tag: I18n.t('Tag'),
      strand: I18n.t('Strand'),
      singleton: I18n.t('Singleton'),
    }
  }, [])

  const groupTitles = useMemo(() => {
    return {
      tag: I18n.t('Tags'),
      strand: I18n.t('Strands'),
      singleton: I18n.t('Singletons'),
    }
  }, [])

  const convertTimestamp = useCallback(
    timestamp => {
      if (!timestamp) return ''

      // convert from the profile timezone
      const plainDate = tz.format(timestamp, '%F %T')

      // interpret in the selected timezone
      return moment.tz(plainDate, state.time_zone).toISOString()
    },
    [state.time_zone]
  )

  useFetchApi(
    {
      path: `/api/v1/jobs2/${state.bucket}/by_${state.group_type}`,
      params: {
        order: state.group_order,
        page: state.groups_page,
        scope: state.scope,
        start_date: convertTimestamp(state.start_date),
        end_date: convertTimestamp(state.end_date),
      },
      loading: useCallback(loading => {
        dispatch({type: 'GROUPS_LOADING', payload: loading})
      }, []),
      meta: useCallback(response => {
        dispatch({type: 'GROUP_METADATA', payload: response})
      }, []),
      success: useCallback(response => {
        dispatch({type: 'FETCHED_GROUPS', payload: response})
      }, []),
    },
    [state.groups_refresh_nonce]
  )

  useFetchApi(
    {
      path: `/api/v1/jobs2/${state.bucket}`,
      params: {
        [state.group_type]: state.group_text,
        order: state.jobs_order,
        page: state.jobs_page,
        scope: state.scope,
        start_date: convertTimestamp(state.start_date),
        end_date: convertTimestamp(state.end_date),
      },
      loading: useCallback(loading => {
        dispatch({type: 'JOBS_LOADING', payload: loading})
      }, []),
      meta: useCallback(response => {
        dispatch({type: 'JOBS_METADATA', payload: response})
      }, []),
      success: useCallback(response => {
        dispatch({type: 'FETCHED_JOBS', payload: response})
      }, []),
    },
    [state.jobs_refresh_nonce]
  )

  useEffect(() => {
    const interval = state.auto_refresh
      ? setInterval(() => dispatch({type: 'REFRESH_ALL'}), AUTO_REFRESH_INTERVAL)
      : null
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [state.auto_refresh])

  return (
    <>
      <Heading level="h1" margin="0 0 small 0">
        <ScreenReaderContent>{I18n.t('Jobs Control Panel')}</ScreenReaderContent>
      </Heading>
      <JobsHeader
        jobBucket={state.bucket}
        onChangeBucket={event => dispatch({type: 'CHANGE_BUCKET', payload: event.target.value})}
        jobGroup={state.group_type}
        onChangeGroup={event => dispatch({type: 'CHANGE_GROUP_TYPE', payload: event.target.value})}
        jobScope={state.scope}
        onChangeScope={(event, {id}) => dispatch({type: 'CHANGE_SCOPE', payload: id})}
        autoRefresh={state.auto_refresh}
        onChangeAutoRefresh={event =>
          dispatch({type: 'TOGGLE_AUTO_REFRESH', payload: event.target.value})
        }
        startDate={state.start_date}
        endDate={state.end_date}
        timeZone={state.time_zone}
        onChangeDateOptions={opts => dispatch({type: 'CHANGE_DATE_OPTIONS', payload: opts})}
      />
      <SectionRefreshHeader
        title={groupTitles[state.group_type]}
        loadingTitle={I18n.t('Loading %{group}', {group: groupTitles[state.group_type]})}
        loading={state.groups_loading}
        onRefresh={() => dispatch({type: 'REFRESH_GROUPS'})}
        autoRefresh={state.auto_refresh}
      />
      <GroupsTable
        type={state.group_type}
        typeCaption={groupCaptions[state.group_type]}
        groups={state.groups}
        bucket={state.bucket}
        caption={bucketCaptions[state.bucket]}
        sortColumn={state.group_order}
        onClickGroup={text => {
          jobListRef.current?.scrollIntoView()
          dispatch({type: 'CHANGE_GROUP_TEXT', payload: text})
        }}
        onClickHeader={col => dispatch({type: 'CHANGE_GROUP_ORDER', payload: col})}
        onUnblock={() => dispatch({type: 'REFRESH_ALL'})}
        timeZone={state.time_zone}
      />
      {state.groups_page_count > 1 ? (
        <Paginator
          pageCount={state.groups_page_count}
          page={state.groups_page}
          loadPage={page => dispatch({type: 'CHANGE_GROUPS_PAGE', payload: page})}
          margin="small"
        />
      ) : null}
      <Flex alignItems="end" elementRef={el => (jobListRef.current = el)}>
        <Flex.Item size="33%">
          <SectionRefreshHeader
            title={I18n.t('Jobs')}
            loadingTitle={I18n.t('Loading jobs...')}
            loading={state.jobs_loading}
            onRefresh={() => dispatch({type: 'REFRESH_JOBS'})}
            autoRefresh={state.auto_refresh}
          />
        </Flex.Item>
        {ENV.manage_jobs &&
        state.bucket !== 'failed' &&
        state.group_text &&
        state.jobs?.length > 0 ? (
          <Flex.Item padding="large small small 0">
            {state.group_type === 'strand' ? (
              <StrandManager
                strand={state.group_text}
                jobs={state.jobs}
                onUpdate={() => dispatch({type: 'REFRESH_ALL'})}
              />
            ) : (
              <TagThrottle
                tag={state.group_text}
                jobs={state.jobs}
                onUpdate={result => {
                  dispatch({type: 'CHANGE_GROUP_TYPE', payload: 'strand'})
                  dispatch({type: 'CHANGE_GROUP_TEXT', payload: result.new_strand})
                }}
              />
            )}
          </Flex.Item>
        ) : null}
        <Flex.Item size="33%" shouldGrow={true} padding="large 0 small 0">
          <SearchBox
            bucket={state.bucket}
            group={state.group_type}
            manualSelection={state.group_text}
            setSelectedItem={item => {
              dispatch({type: 'CHANGE_GROUP_TEXT', payload: item?.name || ''})
            }}
          />
        </Flex.Item>
        <Flex.Item padding="large 0 small xx-small">
          <IconButton
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Clear search')}
            renderIcon={<IconXSolid />}
            interaction={state.group_text === '' ? 'disabled' : 'enabled'}
            onClick={() => dispatch({type: 'CHANGE_GROUP_TEXT', payload: ''})}
          />
        </Flex.Item>
      </Flex>
      <JobsTable
        bucket={state.bucket}
        jobs={state.jobs}
        caption={bucketCaptions[state.bucket]}
        sortColumn={state.jobs_order}
        onClickJob={job => {
          jobDetailsRef.current?.scrollIntoView()
          dispatch({type: 'SELECT_JOB', payload: job})
        }}
        onClickFilter={(groupType, groupText) => {
          if (groupType !== state.group_type) {
            dispatch({type: 'CHANGE_GROUP_TYPE', payload: groupType})
          }
          dispatch({type: 'CHANGE_GROUP_TEXT', payload: groupText})
        }}
        onClickHeader={col => dispatch({type: 'CHANGE_JOBS_ORDER', payload: col})}
        timeZone={state.time_zone}
      />
      {state.jobs_page_count > 1 ? (
        <Paginator
          pageCount={state.jobs_page_count}
          page={state.jobs_page}
          loadPage={page => dispatch({type: 'CHANGE_JOBS_PAGE', payload: page})}
          margin="small"
        />
      ) : null}
      <Flex alignItems="end" elementRef={el => (jobDetailsRef.current = el)}>
        <Flex.Item size="33%">
          <Heading level="h2" margin="x-large 0 small 0">
            {I18n.t('Details')}
          </Heading>
        </Flex.Item>
        <Flex.Item size="33%" shouldGrow={true} padding="large 0 small 0">
          <JobLookup
            manualSelection={state.job?.id || ''}
            setSelectedItem={item => {
              dispatch({type: 'SELECT_JOB', payload: item})
            }}
          />
        </Flex.Item>
        <Flex.Item padding="large 0 small xx-small">
          <IconButton
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Clear job selection')}
            renderIcon={<IconXSolid />}
            interaction={state.job ? 'enabled' : 'disabled'}
            onClick={() => dispatch({type: 'SELECT_JOB', payload: null})}
          />
        </Flex.Item>
      </Flex>
      <JobDetails
        job={state.job}
        timeZone={state.time_zone}
        onRequeue={() => dispatch({type: 'REFRESH_JOBS'})}
      />
    </>
  )
}
