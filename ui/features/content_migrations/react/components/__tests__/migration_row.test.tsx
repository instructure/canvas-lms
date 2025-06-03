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
import {Table} from '@instructure/ui-table'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('content_migrations_redesign')

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

const completedMigration = {
  ...migration,
  ...{workflow_state: 'completed'},
}

const failedMigration = {
  ...migration,
  ...{workflow_state: 'failed'},
}

const waitingForSelectMigration = {
  ...migration,
  ...{workflow_state: 'waiting_for_select'},
}

const progressHit = {method: 'GET', path: 'https://mock.progress.url'}

jest.mock('@canvas/do-fetch-api-effect')

const updateMigrationItem = jest.fn()

const renderComponent = (overrideProps?: any) => {
  const layout = overrideProps?.layout || 'auto'
  render(
    <Table caption={I18n.t('Content migrations')} layout={layout}>
      <Table.Body>
        <MigrationRow
          migration={migration}
          updateMigrationItem={updateMigrationItem}
          {...overrideProps}
        />
      </Table.Body>
    </Table>,
  )
}

describe('MigrationRow', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the proper view if extended', async () => {
    renderComponent()
    await waitFor(() => expect(screen.getByText('Copy a Canvas Course').tagName).toEqual('TD'))
  })

  it('renders the proper view if condensed', async () => {
    renderComponent({layout: 'stacked'})
    await waitFor(() => expect(screen.getByText('Copy a Canvas Course').tagName).toEqual('DIV'))
  })

  it('polls for progress when appropriate', async () => {
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}}),
    )
    renderComponent({migration: runningMigration})
    // @ts-expect-error
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit]]))
  })

  it('stops polling on fail', async () => {
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 60, workflow_state: 'running'}}),
    )
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 60, workflow_state: 'failed'}}),
    )
    renderComponent({migration: runningMigration})
    // @ts-expect-error
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit], [progressHit]]))
  })

  it('stops polling on complete', async () => {
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}}),
    )
    renderComponent({migration: runningMigration})
    // @ts-expect-error
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit]]))
  })

  it('updates migration correctly for each progress poll', async () => {
    const mockCallback = jest.fn()
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 50, workflow_state: 'running'}}),
    )
    // @ts-expect-error
    doFetchApi.mockReturnValueOnce(
      Promise.resolve({json: {completion: 100, workflow_state: 'completed'}}),
    )
    renderComponent({migration: queuedMigration, updateMigrationItem: mockCallback})
    // @ts-expect-error
    await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit], [progressHit]]))
    await waitFor(() =>
      expect(mockCallback.mock.calls).toEqual([
        [expect.anything(), {completion: 50}, true],
        [expect.anything(), {completion: 100}],
      ]),
    )
  })

  describe('Status scenarios', () => {
    // this is needed because the initial state triggers the fetchProgress function
    const mockFetchProgressPolling = () => {
      // @ts-expect-error
      doFetchApi.mockReturnValueOnce(
        Promise.resolve({json: {completion: 100, workflow_state: 'completed'}}),
      )
    }

    describe('initial state setting', () => {
      describe('queued', () => {
        beforeEach(() => {
          mockFetchProgressPolling()
        })

        it('should render queued state', () => {
          renderComponent({migration: queuedMigration, updateMigrationItem: jest.fn()})
          expect(screen.getByText('Queued')).toBeInTheDocument()
        })

        it('should start polling', async () => {
          const mockCallback = jest.fn()
          renderComponent({migration: queuedMigration, updateMigrationItem: mockCallback})
          await waitFor(() => expect(mockCallback).toHaveBeenCalled())
        })
      })

      describe('running', () => {
        beforeEach(() => {
          mockFetchProgressPolling()
        })

        it('should render running state', () => {
          renderComponent({migration: runningMigration, updateMigrationItem: jest.fn()})
          expect(screen.getByText('Running')).toBeInTheDocument()
        })

        it('should start polling', async () => {
          const mockCallback = jest.fn()
          renderComponent({migration: runningMigration, updateMigrationItem: mockCallback})
          await waitFor(() => expect(mockCallback).toHaveBeenCalled())
        })
      })

      describe('completed', () => {
        it('should render completed state', () => {
          renderComponent({migration: completedMigration, updateMigrationItem: jest.fn()})
          expect(screen.getByText('Completed')).toBeInTheDocument()
        })

        it('should not start polling', async () => {
          const mockCallback = jest.fn()
          renderComponent({migration: completedMigration, updateMigrationItem: mockCallback})
          await waitFor(() => expect(mockCallback).not.toHaveBeenCalled())
        })
      })

      describe('failed', () => {
        it('should render completed state', () => {
          renderComponent({migration: failedMigration, updateMigrationItem: jest.fn()})
          expect(screen.getByText('Failed')).toBeInTheDocument()
        })

        it('should not start polling', async () => {
          const mockCallback = jest.fn()
          renderComponent({migration: failedMigration, updateMigrationItem: mockCallback})
          await waitFor(() => expect(mockCallback).not.toHaveBeenCalled())
        })
      })

      describe('wait_for_selection', () => {
        it('should render completed state', () => {
          renderComponent({migration: waitingForSelectMigration, updateMigrationItem: jest.fn()})
          expect(screen.getByText('Waiting for selection')).toBeInTheDocument()
        })

        it('should not start polling', async () => {
          const mockCallback = jest.fn()
          renderComponent({migration: waitingForSelectMigration, updateMigrationItem: mockCallback})
          await waitFor(() => expect(mockCallback).not.toHaveBeenCalled())
        })
      })
    })

    describe('update status on progress done state', () => {
      describe('when content_migration update result is not waiting_for_select', () => {
        it('should render progress state', async () => {
          // Content migration returns completed
          const mockCallback = jest
            .fn()
            .mockReturnValue(Promise.resolve({workflow_state: 'completed'}))
          // Progress returns fails
          // @ts-expect-error
          doFetchApi.mockReturnValueOnce(
            Promise.resolve({json: {completion: 100, workflow_state: 'failed'}}),
          )
          renderComponent({migration: queuedMigration, updateMigrationItem: mockCallback})
          await waitFor(() => {
            expect(mockCallback).toHaveBeenCalled()
            // Progress workflow_state should be rendered
            expect(screen.getByText('Failed')).toBeInTheDocument()
          })
        })
      })

      describe('when content_migration update result is waiting_for_select', () => {
        it('should not render progress state', async () => {
          // Content migration returns waiting_for_select
          const mockCallback = jest
            .fn()
            .mockReturnValue(Promise.resolve({workflow_state: 'waiting_for_select'}))
          // Progress returns completed
          // @ts-expect-error
          doFetchApi.mockReturnValueOnce(
            Promise.resolve({json: {completion: 100, workflow_state: 'completed'}}),
          )
          // The initial status
          renderComponent({migration: queuedMigration, updateMigrationItem: mockCallback})
          // await waitFor(() => expect(doFetchApi.mock.calls).toEqual([[progressHit], [progressHit]]))
          await waitFor(() => {
            expect(mockCallback).toHaveBeenCalled()
            // The initial status should stay
            expect(screen.getByText('Queued')).toBeInTheDocument()
          })
        })
      })
    })
  })
})
