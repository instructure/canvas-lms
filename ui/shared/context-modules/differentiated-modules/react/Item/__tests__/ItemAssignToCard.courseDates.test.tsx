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
import {render, fireEvent, waitFor} from '@testing-library/react'
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

const props: ItemAssignToCardProps = {
  courseId: '1',
  disabledOptionIdsRef: {current: []},
  selectedAssigneeIds: [],
  onCardAssignmentChange: () => {},
  cardId: 'assign-to-card-001',
  due_at: null,
  original_due_at: null,
  unlock_at: null,
  lock_at: null,
  peer_review_available_from: null,
  peer_review_available_to: null,
  peer_review_due_at: null,
  onDelete: undefined,
  removeDueDateInput: false,
  isCheckpointed: false,
  onValidityChange: () => {},
  required_replies_due_at: null,
  reply_to_topic_due_at: null,
}

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) =>
  render(
    <MockedQueryProvider>
      <ItemAssignToCard {...props} {...overrides} />
    </MockedQueryProvider>,
  )

describe('ItemAssignToCard - Course Dates', () => {
  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/1/modules/2/assignment_overrides`
  const COURSE_SETTINGS_URL = `/api/v1/courses/1/settings`

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup({
      HAS_GRADING_PERIODS: false,
      active_grading_periods: [],
      current_user_is_admin: false,
      VALID_DATE_RANGE: {
        start_at: {date: '2025-02-09T00:00:00-06:00', date_context: 'course'},
        end_at: {date: '2025-04-22T23:59:59-06:00', date_context: 'course'},
      },
      SECTION_LIST: [
        {
          id: '1',
          override_course_and_term_dates: false,
          start_at: '2025-02-09T00:00:00-06:00',
          end_at: '2025-06-22T23:59:59-06:00',
        },
      ],
    })
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get(ASSIGNMENT_OVERRIDES_URL, () => {
        return HttpResponse.json([])
      }),
      http.get(COURSE_SETTINGS_URL, () => {
        return HttpResponse.json({hide_final_grades: false})
      }),
    )
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  it('renders error when date is outside of course dates', async () => {
    const {getByLabelText, getAllByRole, getAllByText} = renderComponent()
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'May 4, 2025'}})
    getAllByRole('option', {name: '4 May 2025'})[0].click()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('May 4, 2025')
      expect(getAllByText(/Due date cannot be after course end/).length).toBeGreaterThanOrEqual(1)
    })
  })

  it('does not render error when date is outside of course dates but assignees are ADHOC', async () => {
    const {getByLabelText, getAllByRole, queryByText} = renderComponent({
      customAllOptions: [{id: 'student-1', value: 'John'}],
      selectedAssigneeIds: ['student-1'],
    })
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'May 4, 2025'}})
    getAllByRole('option', {name: '4 May 2025'})[0].click()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('May 4, 2025')
      expect(queryByText(/Due date cannot be after course end/)).not.toBeInTheDocument()
    })
  })

  it('does not render error when date is outside of course dates but inside section dates', async () => {
    const {getByLabelText, getAllByRole, queryByText} = renderComponent({
      customAllOptions: [{id: 'section-1', value: 'Section 1'}],
      selectedAssigneeIds: ['section-1'],
    })
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'May 4, 2025'}})
    getAllByRole('option', {name: '4 May 2025'})[0].click()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('May 4, 2025')
      expect(queryByText(/Due date cannot be after course end/)).not.toBeInTheDocument()
    })
  })
})
