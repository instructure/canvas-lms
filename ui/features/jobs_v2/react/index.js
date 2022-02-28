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
import TagsTable from './components/TagsTable'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('jobs_v2')

function jobsReducer(prevState, action) {
  if (action.type === 'FETCHED_JOBS') {
    return {...prevState, jobs: action.payload}
  } else if (action.type === 'FETCHED_TAGS') {
    return {...prevState, tags: action.payload, jobs: []}
  } else if (action.type === 'CHANGE_BUCKET') {
    return {...prevState, bucket: action.payload, tag: ''}
  } else if (action.type === 'CHANGE_TAG') {
    return {...prevState, tag: action.payload}
  }
}

export default function JobsIndex() {
  const [state, dispatch] = useReducer(jobsReducer, {
    bucket: 'running',
    tag: '',
    tags: [],
    jobs: []
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
    path: `/api/v1/jobs2/${state.bucket}/by_tag`,
    success: useCallback(response => {
      dispatch({type: 'FETCHED_TAGS', payload: response})
    }, [])
  })

  useFetchApi({
    path: `/api/v1/jobs2/${state.bucket}`,
    params: {
      tag: state.tag
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
        onChange={event => dispatch({type: 'CHANGE_BUCKET', payload: event.target.value})}
      />
      <Heading level="h2" margin="large 0 small 0">
        {I18n.t('Tags')}
      </Heading>
      <TagsTable
        tags={state.tags}
        bucket={state.bucket}
        caption={captions[state.bucket]}
        onClickTag={tag => dispatch({type: 'CHANGE_TAG', payload: tag})}
      />
      <Heading level="h2" margin="large 0 small 0">
        {I18n.t('Jobs')}
      </Heading>
      <JobsTable bucket={state.bucket} jobs={state.jobs} caption={captions[state.bucket]} />
    </>
  )
}
