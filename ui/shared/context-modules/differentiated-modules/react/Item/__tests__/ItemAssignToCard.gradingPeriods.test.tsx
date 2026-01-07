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

const setupGradingPeriodsMock = () => {
  fakeENV.setup({
    HAS_GRADING_PERIODS: true,
    current_user_is_admin: false,
    active_grading_periods: [
      {
        id: '2',
        start_date: '2024-05-02T00:00:00-06:00',
        end_date: '2024-05-06T23:59:59-06:00',
        title: 'period 2',
        close_date: '2024-05-06T23:59:59-06:00',
        is_last: false,
        is_closed: true,
      },
      {
        id: '1',
        start_date: '2024-05-09T00:00:00-06:00',
        end_date: '2024-05-22T23:59:59-06:00',
        title: 'period 1',
        close_date: '2024-05-22T23:59:59-06:00',
        is_last: true,
        is_closed: false,
      },
    ],
  })
}

describe('ItemAssignToCard - Grading Periods', () => {
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

  it('renders all disabled when date falls in a closed grading period for teacher', () => {
    setupGradingPeriodsMock()

    const due_at = '2024-05-05T00:00:00-06:00'
    const original_due_at = '2024-05-05T00:00:00-06:00'
    const {getByLabelText} = renderComponent({due_at, original_due_at})
    expect(getByLabelText('Due Date')).toHaveValue('May 5, 2024')
    expect(getByLabelText('Due Date')).toBeDisabled()
  })

  it('renders all fields when date falls in a closed grading period for admin', () => {
    setupGradingPeriodsMock()
    window.ENV.current_user_is_admin = true

    const due_at = '2024-05-05T00:00:00-06:00'
    const original_due_at = '2024-05-05T00:00:00-06:00'
    const {getByLabelText} = renderComponent({due_at, original_due_at})
    expect(getByLabelText('Due Date')).toHaveValue('May 5, 2024')
    expect(getByLabelText('Due Date')).not.toBeDisabled()
  })

  it('renders error when date change to a closed grading period for teacher', async () => {
    setupGradingPeriodsMock()
    window.ENV.current_user_is_admin = false

    const due_at = '2024-05-17T00:00:00-06:00'
    const original_due_at = '2024-05-17T00:00:00-06:00'
    const {getByLabelText, getAllByText, getAllByRole} = renderComponent({due_at, original_due_at})

    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'May 4, 2024'}})
    getAllByRole('option', {name: '4 May 2024'})[0].click()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('May 4, 2024')
      expect(getAllByText(/Please enter a due date on or after/).length).toBeGreaterThanOrEqual(1)
    })
  })
})
