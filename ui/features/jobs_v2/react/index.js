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

import React, {useCallback, useReducer} from 'react'
import {Table} from '@instructure/ui-table'
import useFetchApi from '@canvas/use-fetch-api-hook'

function jobsReducer(prevState, action) {
  if (action.type === 'FETCH_SUCCESS') {
    return {...prevState, jobs: action.payload.jobs}
  }
}

function renderJobRow(job) {
  const cellTheme = {fontSize: '0.75rem'}

  return (
    <Table.Row key={job.id}>
      <Table.RowHeader>{job.id}</Table.RowHeader>
      <Table.Cell theme={cellTheme}>{job.tag}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.strand}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.singleton}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.run_at}</Table.Cell>
    </Table.Row>
  )
}

export default function JobsIndex() {
  const [state, dispatch] = useReducer(jobsReducer, {
    jobs: []
  })

  useFetchApi({
    path: '/jobs',
    params: {
      flavor: 'future',
      only: 'jobs'
    },
    success: useCallback(response => {
      dispatch({type: 'FETCH_SUCCESS', payload: response})
    }, [])
  })

  return (
    <div>
      <Table caption="Future Jobs">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader>ID</Table.ColHeader>
            <Table.ColHeader>Tag</Table.ColHeader>
            <Table.ColHeader>Strand</Table.ColHeader>
            <Table.ColHeader>Singleton</Table.ColHeader>
            <Table.ColHeader>Run At</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {state.jobs.map(job => {
            return renderJobRow(job)
          })}
        </Table.Body>
      </Table>
    </div>
  )
}
