/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import MigrationRow from '../migration_row'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('../utils', () => ({
  timeout: (_delay: number) => {
    return new Promise(resolve => {
      return resolve(true)
    })
  },
}))

const migration = {
  id: '2',
  migration_type: 'course_copy_importer',
  migration_type_title: 'Copy a Canvas Course',
  progress_url: false,
  settings: {
    source_course_id: '456',
    source_course_name: 'Other course',
    source_course_html_url: 'http://mock.other-course.url',
  },
  workflow_state: 'waiting_for_select',
  migration_issues_count: 0,
  migration_issues_url: 'http://mock.issues.url',
  created_at: 'Apr 15 at 9:11pm',
}

const queuedMigration = {
  ...migration,
  ...{progress_url: 'https://mock.progress.url', workflow_state: 'queued'},
}

const runningMigration = {
  ...migration,
  ...{progress_url: 'https://mock.progress.url', workflow_state: 'running'},
}

const progressHit = {method: 'GET', path: 'https://mock.progress.url'}

jest.mock('@canvas/do-fetch-api-effect')

const updateMigrationItem = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(
    <table>
      <tbody>
        <MigrationRow
          migration={migration}
          updateMigrationItem={updateMigrationItem}
          {...overrideProps}
        />
      </tbody>
    </table>
  )

const renderCondensedComponent = (overrideProps?: any) =>
  render(
    <MigrationRow
      migration={migration}
      updateMigrationItem={updateMigrationItem}
      {...overrideProps}
    />
  )

describe('MigrationRow', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the proper view if extended', async () => {
    renderComponent({view: 'extended'})
    await waitFor(() => expect(screen.getByText('Copy a Canvas Course').tagName).toEqual('TD'))
  })

  it('renders the proper view if condensed', async () => {
    renderCondensedComponent({view: 'condensed'})
    await waitFor(() => expect(screen.getByText('Copy a Canvas Course').tagName).toEqual('SPAN'))
  })

  it('polls for progress when appropriate', async () => {
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}})
    )
    renderComponent({migration: runningMigration})
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit]]))
  })

  it('stops polling on fail', async () => {
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 60, workflow_state: 'running'}})
    )
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 60, workflow_state: 'failed'}})
    )
    renderComponent({migration: runningMigration})
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit], [progressHit]]))
  })

  it('stops polling on complete', async () => {
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}})
    )
    renderComponent({migration: runningMigration})
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit]]))
  })

  it('updates migration correctly for each progress poll', async () => {
    const mockCallback = jest.fn()
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 50, workflow_state: 'running'}})
    )
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}})
    )
    renderComponent({migration: queuedMigration, updateMigrationItem: mockCallback})
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit], [progressHit]]))
    await waitFor(() =>
      expect(mockCallback.mock.calls).toEqual([
        [expect.anything(), {completion: 50}, true],
        [expect.anything(), {completion: 100}],
      ])
    )
  })
})
