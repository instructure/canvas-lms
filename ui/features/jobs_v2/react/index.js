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
import JobsHeader from './components/JobsHeader'
import JobsTable from './components/JobsTable'
import GroupsTable from './components/GroupsTable'
import JobDetails from './components/JobDetails'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('jobs_v2')

function jobsReducer(prevState, action) {
  if (action.type === 'CHANGE_BUCKET') {
    return {...prevState, bucket: action.payload, groups: [], jobs: [], job: null, group_text: ''}
  } else if (action.type === 'CHANGE_GROUP_TYPE') {
    return {...prevState, group_type: action.payload, groups: [], jobs: [], job: null}
  } else if (action.type === 'CHANGE_GROUP_ORDER') {
    return {...prevState, group_order: action.payload, groups: []}
  } else if (action.type === 'FETCHED_GROUPS') {
    return {...prevState, groups: action.payload}
  } else if (action.type === 'CHANGE_GROUP_TEXT') {
    return {...prevState, group_text: action.payload, jobs: [], job: null}
  } else if (action.type === 'CHANGE_JOBS_ORDER') {
    return {...prevState, jobs_order: action.payload, jobs: [], job: null}
  } else if (action.type === 'FETCHED_JOBS') {
    return {...prevState, jobs: action.payload, job: null}
  } else if (action.type === 'SELECT_JOB') {
    return {...prevState, job: action.payload}
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
    job: null
  })

  const captions = useMemo(() => {
    return {
      queued: I18n.t('Queued jobs'),
      running: I18n.t('Running jobs'),
      future: I18n.t('Future jobs'),
      failed: I18n.t('Failed jobs')
    }
  }, [])

  useFetchApi({
    path: `/api/v1/jobs2/${state.bucket}/by_${state.group_type}`,
    params: {
      order: state.group_order
    },
    success: useCallback(response => {
      dispatch({type: 'FETCHED_GROUPS', payload: response})
    }, [])
  })

  useFetchApi({
    path: `/api/v1/jobs2/${state.bucket}`,
    params: {
      [state.group_type]: state.group_text,
      order: state.jobs_order
    },
    success: useCallback(response => {
      dispatch({type: 'FETCHED_JOBS', payload: response})
    }, [])
  })

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
      />
      <Heading level="h2" margin="large 0 small 0">
        {state.group_type === 'tag' ? I18n.t('Tags') : I18n.t('Strands')}
      </Heading>
      <GroupsTable
        type={state.group_type}
        groups={state.groups}
        bucket={state.bucket}
        caption={captions[state.bucket]}
        sortColumn={state.group_order}
        onClickGroup={text => dispatch({type: 'CHANGE_GROUP_TEXT', payload: text})}
        onClickHeader={col => dispatch({type: 'CHANGE_GROUP_ORDER', payload: col})}
      />
      <Heading level="h2" margin="large 0 small 0">
        {I18n.t('Jobs')}
      </Heading>
      <JobsTable
        bucket={state.bucket}
        jobs={state.jobs}
        caption={captions[state.bucket]}
        sortColumn={state.jobs_order}
        onClickJob={job => dispatch({type: 'SELECT_JOB', payload: job})}
        onClickHeader={col => dispatch({type: 'CHANGE_JOBS_ORDER', payload: col})}
      />
      <Heading level="h2" margin="large 0 small 0">
        {I18n.t('Details')}
      </Heading>
      <JobDetails job={state.job} />
    </>
  )
}
