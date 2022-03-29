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
import React, {useCallback, useReducer, useMemo} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import JobsHeader from './components/JobsHeader'
import JobsTable from './components/JobsTable'
import GroupsTable from './components/GroupsTable'
import JobDetails from './components/JobDetails'
import SearchBox from './components/SearchBox'
import JobLookup from './components/JobLookup'
import SectionRefreshHeader from './components/SectionRefreshHeader'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid} from '@instructure/ui-icons'

const I18n = useI18nScope('jobs_v2')

function jobsReducer(prevState, action) {
  if (action.type === 'CHANGE_BUCKET') {
    return {
      ...prevState,
      bucket: action.payload,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1
    }
  } else if (action.type === 'CHANGE_GROUP_TYPE') {
    return {
      ...prevState,
      group_type: action.payload,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1
    }
  } else if (action.type === 'CHANGE_GROUP_ORDER') {
    return {...prevState, group_order: action.payload, groups: []}
  } else if (action.type === 'GROUPS_LOADING') {
    return {...prevState, groups_loading: action.payload}
  } else if (action.type === 'REFRESH_GROUPS') {
    return {...prevState, groups_refresh_nonce: prevState.groups_refresh_nonce + 1}
  } else if (action.type === 'FETCHED_GROUPS') {
    return {...prevState, groups: action.payload}
  } else if (action.type === 'GROUP_METADATA') {
    if (action.payload.link) {
      const last = parseInt(action.payload.link.last.page, 10)
      return {...prevState, groups_page_count: last}
    }
  } else if (action.type === 'CHANGE_GROUPS_PAGE') {
    return {...prevState, groups_page: action.payload}
  } else if (action.type === 'CHANGE_GROUP_TEXT') {
    if (prevState.group_text !== action.payload) {
      return {
        ...prevState,
        group_text: action.payload,
        jobs: [],
        job: null,
        jobs_page: 1,
        jobs_page_count: 1
      }
    } else {
      return prevState
    }
  } else if (action.type === 'CHANGE_JOBS_ORDER') {
    return {...prevState, jobs_order: action.payload, jobs: [], job: null}
  } else if (action.type === 'JOBS_LOADING') {
    return {...prevState, jobs_loading: action.payload}
  } else if (action.type === 'REFRESH_JOBS') {
    return {...prevState, jobs_refresh_nonce: prevState.jobs_refresh_nonce + 1}
  } else if (action.type === 'FETCHED_JOBS') {
    return {...prevState, jobs: action.payload, job: null}
  } else if (action.type === 'JOBS_METADATA') {
    if (action.payload.link) {
      const last = parseInt(action.payload.link.last.page, 10)
      return {...prevState, jobs_page_count: last}
    }
  } else if (action.type === 'CHANGE_JOBS_PAGE') {
    return {...prevState, jobs_page: action.payload}
  } else if (action.type === 'SELECT_JOB') {
    return {...prevState, job: action.payload}
  } else if (action.type === 'CHANGE_SCOPE') {
    return {
      ...prevState,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1,
      scope: action.payload
    }
  }
}

export default function JobsIndex() {
  const [state, dispatch] = useReducer(jobsReducer, {
    bucket: 'running',
    group_text: '',
    group_type: 'tag',
    group_order: 'info',
    jobs_order: 'info',
    groups: [],
    jobs: [],
    job: null,
    jobs_loading: false,
    jobs_page: 1,
    jobs_page_count: 1,
    jobs_refresh_nonce: 1,
    groups_loading: false,
    groups_page: 1,
    groups_page_count: 1,
    groups_refresh_nonce: 1,
    scope: Object.keys(ENV.jobs_scope_filter)[0]
  })

  const bucketCaptions = useMemo(() => {
    return {
      queued: I18n.t('Queued jobs'),
      running: I18n.t('Running jobs'),
      future: I18n.t('Future jobs'),
      failed: I18n.t('Failed jobs')
    }
  }, [])

  const groupCaptions = useMemo(() => {
    return {
      tag: I18n.t('Tag'),
      strand: I18n.t('Strand'),
      singleton: I18n.t('Singleton')
    }
  }, [])

  const groupTitles = useMemo(() => {
    return {
      tag: I18n.t('Tags'),
      strand: I18n.t('Strands'),
      singleton: I18n.t('Singletons')
    }
  }, [])

  useFetchApi(
    {
      path: `/api/v1/jobs2/${state.bucket}/by_${state.group_type}`,
      params: {
        order: state.group_order,
        page: state.groups_page,
        scope: state.scope
      },
      loading: useCallback(loading => {
        dispatch({type: 'GROUPS_LOADING', payload: loading})
      }, []),
      meta: useCallback(response => {
        dispatch({type: 'GROUP_METADATA', payload: response})
      }, []),
      success: useCallback(response => {
        dispatch({type: 'FETCHED_GROUPS', payload: response})
      }, [])
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
        scope: state.scope
      },
      loading: useCallback(loading => {
        dispatch({type: 'JOBS_LOADING', payload: loading})
      }, []),
      meta: useCallback(response => {
        dispatch({type: 'JOBS_METADATA', payload: response})
      }, []),
      success: useCallback(response => {
        dispatch({type: 'FETCHED_JOBS', payload: response})
      }, [])
    },
    [state.jobs_refresh_nonce]
  )

  return (
    <>
      <Heading level="h1" margin="0 0 small 0">
        {I18n.t('Jobs Control Panel')}
      </Heading>
      <JobsHeader
        jobBucket={state.bucket}
        onChangeBucket={event => dispatch({type: 'CHANGE_BUCKET', payload: event.target.value})}
        jobGroup={state.group_type}
        onChangeGroup={event => dispatch({type: 'CHANGE_GROUP_TYPE', payload: event.target.value})}
        jobScope={state.scope}
        onChangeScope={(event, {id}) => dispatch({type: 'CHANGE_SCOPE', payload: id})}
      />
      <SectionRefreshHeader
        title={groupTitles[state.group_type]}
        loadingTitle={I18n.t('Loading %{group}', {group: groupTitles[state.group_type]})}
        loading={state.groups_loading}
        onRefresh={() => dispatch({type: 'REFRESH_GROUPS'})}
      />
      <GroupsTable
        type={state.group_type}
        typeCaption={groupCaptions[state.group_type]}
        groups={state.groups}
        bucket={state.bucket}
        caption={bucketCaptions[state.bucket]}
        sortColumn={state.group_order}
        onClickGroup={text => dispatch({type: 'CHANGE_GROUP_TEXT', payload: text})}
        onClickHeader={col => dispatch({type: 'CHANGE_GROUP_ORDER', payload: col})}
      />
      {state.groups_page_count > 1 ? (
        <Paginator
          pageCount={state.groups_page_count}
          page={state.groups_page}
          loadPage={page => dispatch({type: 'CHANGE_GROUPS_PAGE', payload: page})}
          margin="small"
        />
      ) : null}
      <Flex alignItems="end">
        <Flex.Item size="33%">
          <SectionRefreshHeader
            title={I18n.t('Jobs')}
            loadingTitle={I18n.t('Loading jobs...')}
            loading={state.jobs_loading}
            onRefresh={() => dispatch({type: 'REFRESH_JOBS'})}
          />
        </Flex.Item>
        <Flex.Item size="33%" shouldGrow padding="large 0 small 0">
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
        onClickJob={job => dispatch({type: 'SELECT_JOB', payload: job})}
        onClickHeader={col => dispatch({type: 'CHANGE_JOBS_ORDER', payload: col})}
      />
      {state.jobs_page_count > 1 ? (
        <Paginator
          pageCount={state.jobs_page_count}
          page={state.jobs_page}
          loadPage={page => dispatch({type: 'CHANGE_JOBS_PAGE', payload: page})}
          margin="small"
        />
      ) : null}
      <Flex alignItems="end">
        <Flex.Item size="33%">
          <Heading level="h2" margin="large 0 small 0">
            {I18n.t('Details')}
          </Heading>
        </Flex.Item>
        <Flex.Item size="33%" shouldGrow padding="large 0 small 0">
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
      <JobDetails job={state.job} />
    </>
  )
}
