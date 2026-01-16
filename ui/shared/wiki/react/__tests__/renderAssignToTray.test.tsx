/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render, waitFor} from '@testing-library/react'
import {renderAssignToTray} from '../renderAssignToTray'
import {queryClient} from '@canvas/query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeEnv from '@canvas/test-utils/fakeENV'

const server = setupServer()

const props = {pageId: '1', onSync: () => {}, pageName: 'Test page'}

export const SECTIONS_DATA = [
  {id: '1', course_id: '1', name: 'Course 1', start_at: null, end_at: null},
  {id: '2', course_id: '1', name: 'Section A', start_at: null, end_at: null},
  {id: '3', course_id: '1', name: 'Section B', start_at: null, end_at: null},
  {id: '4', course_id: '1', name: 'Section C', start_at: null, end_at: null},
]

export const STUDENTS_DATA = [
  {id: '1', name: 'Ben', created_at: '2023-01-01', sortable_name: 'Ben', sis_user_id: 'ben001'},
  {
    id: '2',
    name: 'Peter',
    created_at: '2023-01-01',
    sortable_name: 'Peter',
    sis_user_id: 'peter002',
  },
  {
    id: '3',
    name: 'Grace',
    created_at: '2023-01-01',
    sortable_name: 'Grace',
    sis_user_id: 'grace003',
  },
  {
    id: '4',
    name: 'Secilia',
    created_at: '2023-01-01',
    sortable_name: 'Secilia',
    sis_user_id: 'random_id_8',
  },
]

describe('renderAssignToTray embedded', () => {
  beforeAll(() => {
    server.listen()
    fakeEnv.setup({COURSE_ID: '1'})
  })
  afterAll(() => {
    server.close()
    fakeEnv.teardown()
  })

  beforeEach(() => {
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get('/api/v1/courses/1/modules/2/assignment_overrides', () => {
        return HttpResponse.json([])
      }),
      http.get('/api/v1/courses/1/settings', () => {
        return HttpResponse.json({hide_final_grades: false})
      }),
      http.get('/api/v1/courses/1/pages/1/date_details', () => {
        return HttpResponse.json([])
      }),
    )
    queryClient.setQueryData(['students', '1', {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    server.resetHandlers()
  })

  const container = document.createElement('div')
  container.id = 'assign-to-mount-point'

  it('sets default state for new pages', async () => {
    const assignToOption = renderAssignToTray(container, {...props, pageId: undefined})

    const {findAllByTestId} = render(assignToOption)

    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    await waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Everyone'))
  })
})
