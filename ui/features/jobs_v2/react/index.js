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

import { useScope as useI18nScope } from '@canvas/i18n';
import React, {useCallback, useReducer, useMemo} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import JobsHeader from './components/JobsHeader'
import JobsTable from './components/JobsTable'

const I18n = useI18nScope('jobs_v2');

function jobsReducer(prevState, action) {
  if (action.type === 'FETCH_SUCCESS') {
    return {...prevState, jobs: action.payload}
  } else if (action.type === 'CHANGE_FLAVOR') {
    return {...prevState, flavor: action.payload}
  }
}

export default function JobsIndex() {
  const [state, dispatch] = useReducer(jobsReducer, {
    flavor: 'running',
    jobs: []
  })

  const captions = useMemo(() => {
    return {
      running: I18n.t('Running jobs'),
      current: I18n.t('Current jobs'),
      future: I18n.t('Future jobs'),
      failed: I18n.t('Failed jobs')
    }
  }, [])

  const jobKey = useCallback(() => {
    return state.flavor === 'running' ? 'running' : 'jobs'
  }, [state.flavor])

  useFetchApi({
    path: '/jobs',
    params: {
      flavor: state.flavor === 'running' ? 'current' : state.flavor,
      only: jobKey()
    },
    success: useCallback(
      response => {
        dispatch({type: 'FETCH_SUCCESS', payload: response[jobKey()]})
      },
      [jobKey]
    )
  })

  return (
    <>
      <JobsHeader
        jobFlavor={state.flavor}
        onChange={event => dispatch({type: 'CHANGE_FLAVOR', payload: event.target.value})}
      />
      <JobsTable jobs={state.jobs} caption={captions[state.flavor]} />
    </>
  )
}
