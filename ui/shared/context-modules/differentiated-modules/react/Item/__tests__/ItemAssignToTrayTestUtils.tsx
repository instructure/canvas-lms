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
import {render} from '@testing-library/react'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import ItemAssignToTray, {type ItemAssignToTrayProps} from '../ItemAssignToTray'
import {
  FIRST_GROUP_CATEGORY_DATA,
  SECOND_GROUP_CATEGORY_DATA,
  SECTIONS_DATA,
  STUDENTS_DATA,
} from '../../__tests__/mocks'

export const FIRST_GROUP_CATEGORY_ID = '2'
export const SECOND_GROUP_CATEGORY_ID = '3'
export const FIRST_GROUP_CATEGORY_URL = `/api/v1/group_categories/${FIRST_GROUP_CATEGORY_ID}/groups?per_page=100`
export const SECOND_GROUP_CATEGORY_URL = `/api/v1/group_categories/${SECOND_GROUP_CATEGORY_ID}/groups?per_page=100`
export const SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?per_page=\d+/
export const OVERRIDES_URL = '/api/v1/courses/1/assignments/23/date_details?per_page=100'

export const server = setupServer()

export const DEFAULT_PROPS: ItemAssignToTrayProps = {
  open: true,
  onClose: () => {},
  onDismiss: () => {},
  courseId: '1',
  itemName: 'Item Name',
  itemType: 'assignment',
  iconType: 'assignment',
  itemContentId: '23',
  pointsPossible: 10,
  locale: 'en',
  timezone: 'UTC',
}

export const OVERRIDES = [
  {
    id: '2',
    assignment_id: '23',
    title: 'Sally and Wally',
    due_at: '2023-10-02T12:00:00Z',
    all_day: false,
    all_day_date: '2023-10-02',
    unlock_at: null,
    lock_at: null,
    course_section_id: '4',
  },
]

export const DEFAULT_DATE_DETAILS = {
  id: '23',
  due_at: '2023-10-05T12:00:00Z',
  unlock_at: '2023-10-01T12:00:00Z',
  lock_at: '2023-11-01T12:00:00Z',
  only_visible_to_overrides: false,
  visible_to_everyone: true,
  overrides: OVERRIDES,
}

export const baseMockHandlers = [
  http.get('/api/v1/courses/1/settings', () => {
    return HttpResponse.json({conditional_release: false})
  }),
  // Use path without query params - MSW matches on path and ignores query params
  http.get('/api/v1/courses/1/assignments/23/date_details', () => {
    return HttpResponse.json(DEFAULT_DATE_DETAILS)
  }),
  // an assignment with invalid dates
  http.get('/api/v1/courses/1/assignments/24/date_details', () => {
    return HttpResponse.json({
      id: '24',
      due_at: '2023-09-30T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
    })
  }),
  // an assignment with valid dates and no overrides
  http.get('/api/v1/courses/1/assignments/25/date_details', () => {
    return HttpResponse.json({
      id: '25',
      due_at: '2023-10-05T12:01:00Z',
      unlock_at: null,
      lock_at: null,
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
    })
  }),
  http.get('/api/v1/courses/1/quizzes/23/date_details', () => {
    return HttpResponse.json({})
  }),
  http.get('/api/v1/courses/1/discussion_topics/23/date_details', () => {
    return HttpResponse.json({})
  }),
  http.get('/api/v1/courses/1/pages/23/date_details', () => {
    return HttpResponse.json({})
  }),
  http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
    return HttpResponse.json(SECTIONS_DATA)
  }),
  // Use paths without query params for group categories
  http.get(`/api/v1/group_categories/${FIRST_GROUP_CATEGORY_ID}/groups`, () => {
    return HttpResponse.json(FIRST_GROUP_CATEGORY_DATA)
  }),
  http.get(`/api/v1/group_categories/${SECOND_GROUP_CATEGORY_ID}/groups`, () => {
    return HttpResponse.json(SECOND_GROUP_CATEGORY_DATA)
  }),
]

export function setupBaseMocks() {
  server.use(...baseMockHandlers)
  queryClient.setQueryData(['students', DEFAULT_PROPS.courseId, {per_page: 100}], STUDENTS_DATA)
}

export function setupEnv() {
  // @ts-expect-error - window.ENV is a Canvas global not in TS types
  window.ENV ||= {}
  ENV.VALID_DATE_RANGE = {
    start_at: {date: '2023-08-20T12:00:00Z', date_context: 'course'},
    end_at: {date: '2023-12-30T12:00:00Z', date_context: 'course'},
  }
  ENV.HAS_GRADING_PERIODS = false
  // @ts-expect-error - ENV.SECTION_LIST type mismatch
  ENV.SECTION_LIST = [{id: '4'}, {id: '5'}]
  ENV.POST_TO_SIS = false
  ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = false
  ENV.MASTER_COURSE_DATA = undefined
}

export function setupFlashHolder() {
  if (!document.getElementById('flash_screenreader_holder')) {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
}

export function renderComponent(overrides: Partial<ItemAssignToTrayProps> = {}) {
  return render(
    <MockedQueryProvider>
      <ItemAssignToTray {...DEFAULT_PROPS} {...overrides} />
    </MockedQueryProvider>,
  )
}

export {SECTIONS_DATA, FIRST_GROUP_CATEGORY_DATA, SECOND_GROUP_CATEGORY_DATA, STUDENTS_DATA}
export {http, HttpResponse}
