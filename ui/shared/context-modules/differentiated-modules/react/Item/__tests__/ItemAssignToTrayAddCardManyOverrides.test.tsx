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

import {act, cleanup} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import {queryClient} from '@canvas/query'
import {
  DEFAULT_PROPS,
  renderComponent,
  FIRST_GROUP_CATEGORY_DATA,
  SECOND_GROUP_CATEGORY_DATA,
  SECTIONS_DATA,
  STUDENTS_DATA,
  setupFlashHolder,
  server,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Add Card with Many Overrides', () => {
  beforeAll(() => {
    server.listen()
    setupFlashHolder()
  })

  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({
      VALID_DATE_RANGE: {
        start_at: {date: '2023-08-20T12:00:00Z', date_context: 'course'},
        end_at: {date: '2023-12-30T12:00:00Z', date_context: 'course'},
      },
      HAS_GRADING_PERIODS: false,
      SECTION_LIST: [{id: '4'}, {id: '5'}, {id: '6'}],
      POST_TO_SIS: false,
      DUE_DATE_REQUIRED_FOR_ACCOUNT: false,
      MASTER_COURSE_DATA: undefined,
    })
    // Setup base mocks
    server.use(
      http.get('/api/v1/courses/1/settings', () => {
        return HttpResponse.json({conditional_release: false})
      }),
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get('/api/v1/group_categories/2/groups', () => {
        return HttpResponse.json(FIRST_GROUP_CATEGORY_DATA)
      }),
      http.get('/api/v1/group_categories/3/groups', () => {
        return HttpResponse.json(SECOND_GROUP_CATEGORY_DATA)
      }),
    )
    queryClient.setQueryData(['students', DEFAULT_PROPS.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    fakeENV.teardown()
    server.resetHandlers()
    cleanup()
  })

  // Rendering 4 cards is slow; increase timeout for CI stability
  it('shows top add button if more than 3 cards exist', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
        return HttpResponse.json({
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          visible_to_everyone: true,
          overrides: [
            {
              id: '2',
              assignment_id: '23',
              course_section_id: '4',
            },
            {
              id: '3',
              assignment_id: '23',
              course_section_id: '5',
            },
            {
              id: '4',
              assignment_id: '23',
              course_section_id: '6',
            },
          ],
        })
      }),
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(4)
    expect(getAllByTestId('add-card')).toHaveLength(2)
    act(() => getAllByTestId('add-card')[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(5)
  }, 30000)
})
