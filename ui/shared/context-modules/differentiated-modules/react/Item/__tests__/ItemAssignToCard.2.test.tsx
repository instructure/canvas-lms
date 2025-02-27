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
import {render, fireEvent, screen, waitFor} from '@testing-library/react'
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import fetchMock from 'fetch-mock'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

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

const withWithGradingPeriodsMock = () => {
  window.ENV = window.ENV || {}
  window.ENV.HAS_GRADING_PERIODS = true
  window.ENV.current_user_is_admin = false
  window.ENV.active_grading_periods = [
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
  ]
}

describe('ItemAssignToCard', () => {
  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/1/modules/2/assignment_overrides?per_page=100`
  const COURSE_SETTINGS_URL = `/api/v1/courses/1/settings`
  const SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?per_page=\d+/

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.HAS_GRADING_PERIODS = false
    window.ENV.active_grading_periods = []
    window.ENV.current_user_is_admin = false
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})
  })

  afterEach(() => {
    fetchMock.restore()
    window.ENV.HAS_GRADING_PERIODS = false
    window.ENV.active_grading_periods = []
    window.ENV.current_user_is_admin = false
  })

  it('renders all disabled when date falls in a closed grading period for teacher', () => {
    withWithGradingPeriodsMock()

    const due_at = '2024-05-05T00:00:00-06:00'
    const original_due_at = '2024-05-05T00:00:00-06:00'
    const {getByLabelText} = renderComponent({due_at, original_due_at})
    expect(getByLabelText('Due Date')).toHaveValue('May 5, 2024')
    expect(getByLabelText('Due Date')).toBeDisabled()
  })

  it('renders all fields when date falls in a closed grading period for admin', () => {
    withWithGradingPeriodsMock()
    window.ENV.current_user_is_admin = true

    const due_at = '2024-05-05T00:00:00-06:00'
    const original_due_at = '2024-05-05T00:00:00-06:00'
    const {getByLabelText} = renderComponent({due_at, original_due_at})
    expect(getByLabelText('Due Date')).toHaveValue('May 5, 2024')
    expect(getByLabelText('Due Date')).not.toBeDisabled()
  })

  it.skip('renders error when date change to a closed grading period for teacher', async () => {
    // Flakey spec
    withWithGradingPeriodsMock()
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

  describe('when course dates are set', () => {
    beforeAll(() => {
      window.ENV.VALID_DATE_RANGE = {
        start_at: {date: '2025-02-09T00:00:00-06:00', date_context: 'course'},
        end_at: {date: '2025-04-22T23:59:59-06:00', date_context: 'course'},
      }
      window.ENV.SECTION_LIST = [
        {
          id: '1',
          override_course_and_term_dates: false,
          start_at: '2025-02-09T00:00:00-06:00',
          end_at: '2025-06-22T23:59:59-06:00',
        },
      ]
    })

    afterAll(() => {
      window.ENV.VALID_DATE_RANGE = undefined
      window.ENV.SECTION_LIST = undefined
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

  it('stops displaying "Unlock date cannot be after reply to topic due date" error when isCheckpointed is set to false', async () => {
    // Provide props that will trigger the error when isCheckpointed is true:
    // In this case, reply_to_topic_due_at is earlier than unlock_at, which triggers the error.
    const errorProps: Partial<ItemAssignToCardProps> = {
      isCheckpointed: true,
      reply_to_topic_due_at: '2024-05-05T00:00:00-06:00',
      unlock_at: '2024-05-06T00:00:00-06:00',
    }
    const {getAllByText, queryByText, rerender} = render(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(
        getAllByText(/Unlock date cannot be after reply to topic due date/i)[0],
      ).toBeInTheDocument()
    })

    // Rerender the component with isCheckpointed set to false.
    rerender(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={false} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(
        queryByText(/Unlock date cannot be after reply to topic due date/i),
      ).not.toBeInTheDocument()
    })
  })

  it('stops displaying "Unlock date cannot be after due date" error when isCheckpointed is set to true', async () => {
    const errorProps: Partial<ItemAssignToCardProps> = {
      isCheckpointed: true,
      due_at: '2024-05-05T00:00:00-06:00',
      unlock_at: '2024-05-06T00:00:00-06:00',
    }
    const {getAllByText, queryByText, rerender} = render(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={false} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(getAllByText(/Unlock date cannot be after due date/i)[0]).toBeInTheDocument()
    })

    // Rerender the component with isCheckpointed set to false.
    rerender(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={true} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(queryByText(/Unlock date cannot be after due date/i)).not.toBeInTheDocument()
    })
  })
})
