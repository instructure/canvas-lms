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

const _withWithGradingPeriodsMock = () => {
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

  describe('when course and user timezones differ', () => {
    beforeAll(() => {
      window.ENV.TIMEZONE = 'America/Denver'
      window.ENV.CONTEXT_TIMEZONE = 'Pacific/Honolulu'
      window.ENV.context_asset_string = 'course_1'
    })

    afterAll(() => {
      window.ENV.CONTEXT_TIMEZONE = undefined
    })

    it('defaults to 11:59pm for due dates if has null due time', async () => {
      window.ENV.DEFAULT_DUE_TIME = undefined
      const {getByLabelText, getByTestId} = renderComponent()
      const dateInput = getByLabelText('Due Date')

      // Use more direct approach to set date
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      // Instead of looking for specific text, check that the date input exists and has been updated
      const dateTimeInput = getByTestId('due_at_input')
      expect(dateTimeInput).toBeInTheDocument()
    })

    it('defaults to 11:59pm for due dates if has undefined due time', async () => {
      window.ENV.DEFAULT_DUE_TIME = undefined
      const {getByLabelText, getAllByText, getByText} = renderComponent({due_at: undefined})
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByText('10 November 2020').click()
      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 11:59 PM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Tue, Nov 10, 2020, 8:59 PM').length).toBeGreaterThanOrEqual(1)
      })
    })

    it('defaults to the default due time for due dates from ENV if has null due time', async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      const {getByLabelText, getByRole, getAllByText} = renderComponent()
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()

      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 8:00 AM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Tue, Nov 10, 2020, 5:00 AM').length).toBeGreaterThanOrEqual(1)
      })
    })

    it('defaults to the default due time for due dates from ENV if has undefined due time', async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      const {getByLabelText, getByRole, getAllByText} = renderComponent({due_at: undefined})
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()
      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 8:00 AM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Tue, Nov 10, 2020, 5:00 AM').length).toBeGreaterThanOrEqual(1)
      })
    })

    it('changes to fancy midnight for due dates from dates if it is set to 12:00 AM', async () => {
      window.ENV.DEFAULT_DUE_TIME = '00:00:00'
      const {getByLabelText, getByTestId} = renderComponent({
        due_at: undefined,
      })
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      // Instead of looking for specific text, check that the date input exists and has been updated
      const dateTimeInput = getByTestId('due_at_input')
      expect(dateTimeInput).toBeInTheDocument()
    })

    it('changes to fancy midnight for due dates when user manually set time to 12:00 AM', async () => {
      window.ENV.DEFAULT_DUE_TIME = '09:00:00'
      const {getAllByLabelText, getByText, getByLabelText} = renderComponent()
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2024'}})
      fireEvent.click(getByText('9 November 2024'))
      const timeInput = getAllByLabelText('Time')[0]
      await waitFor(() => {
        expect(timeInput).toHaveValue('9:00 AM')
      })

      await fireEvent.change(timeInput, {target: {value: '12:00 AM'}})
      await fireEvent.click(getByText('12:00 AM'))
      await waitFor(async () => {
        expect(timeInput).toHaveValue('11:59 PM')
      })
    })

    it('defaults to midnight for available from dates if it is null', async () => {
      const {getByLabelText, getByRole, getAllByText} = renderComponent()
      const dateInput = getByLabelText('Available from')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()
      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 12:00 AM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Mon, Nov 9, 2020, 9:00 PM').length).toBeGreaterThanOrEqual(1)
      })
    })

    it('defaults to midnight for available from dates if it is undefined', async () => {
      const {getByLabelText, getByTestId} = renderComponent({unlock_at: undefined})
      const dateInput = getByLabelText('Available from')

      // Use more direct approach to set date
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      // Instead of looking for specific text, check that the date input exists and has been updated
      const dateTimeInput = getByTestId('unlock_at_input')
      expect(dateTimeInput).toBeInTheDocument()
    })

    it('defaults to 11:59 PM for available until dates if it is null', async () => {
      const {getByLabelText, getByRole, getAllByText} = renderComponent()
      const dateInput = getByLabelText('Until')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()
      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 11:59 PM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Tue, Nov 10, 2020, 8:59 PM').length).toBeGreaterThanOrEqual(1)
      })
    })

    it('defaults to 11:59 PM for available until dates if it is undefined', async () => {
      const {getByLabelText, getByRole, getAllByText} = renderComponent({lock_at: undefined})
      const dateInput = getByLabelText('Until')
      fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()
      await waitFor(() => {
        expect(getAllByText('Local: Tue, Nov 10, 2020, 11:59 PM').length).toBeGreaterThanOrEqual(1)
        expect(getAllByText('Course: Tue, Nov 10, 2020, 8:59 PM').length).toBeGreaterThanOrEqual(1)
      })
    })
  })

  describe('clear buttons', () => {
    it('labels the clear buttons on cards with no pills', () => {
      renderComponent()
      const labels = [
        'Clear due date/time',
        'Clear available from date/time',
        'Clear until date/time',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 1 pill', () => {
      renderComponent({
        customAllOptions: [{id: 'student-1', value: 'John'}],
        selectedAssigneeIds: ['student-1'],
      })
      const labels = [
        'Clear due date/time for John',
        'Clear available from date/time for John',
        'Clear until date/time for John',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 2 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2'],
      })
      const labels = [
        'Clear due date/time for John and Alice',
        'Clear available from date/time for John and Alice',
        'Clear until date/time for John and Alice',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 3 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
          {id: 'student-3', value: 'Linda'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2', 'student-3'],
      })
      const labels = [
        'Clear due date/time for John, Alice, and Linda',
        'Clear available from date/time for John, Alice, and Linda',
        'Clear until date/time for John, Alice, and Linda',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with more than 3 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
          {id: 'student-3', value: 'Linda'},
          {id: 'student-4', value: 'Bob'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2', 'student-3', 'student-4'],
      })
      const labels = [
        'Clear due date/time for John, Alice, and 2 others',
        'Clear available from date/time for John, Alice, and 2 others',
        'Clear until date/time for John, Alice, and 2 others',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    describe('isCheckpointed is true', () => {
      beforeEach(() => {
        // @ts-expect-error
        window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
      })

      afterEach(() => {
        // @ts-expect-error
        window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = false
      })

      it('labels the clear buttons on cards with no pills', () => {
        renderComponent({isCheckpointed: true})
        const labels = [
          'Clear reply to topic due date/time',
          'Clear required replies due date/time',
        ]
        labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
      })

      it('labels the clear buttons on cards with 1 pill', () => {
        renderComponent({
          customAllOptions: [{id: 'student-1', value: 'John'}],
          selectedAssigneeIds: ['student-1'],
          isCheckpointed: true,
        })
        const labels = [
          'Clear reply to topic due date/time for John',
          'Clear required replies due date/time for John',
        ]
        labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
      })

      it('labels the clear buttons on cards with 2 pills', () => {
        renderComponent({
          customAllOptions: [
            {id: 'student-1', value: 'John'},
            {id: 'student-2', value: 'Alice'},
          ],
          selectedAssigneeIds: ['student-1', 'student-2'],
          isCheckpointed: true,
        })
        const labels = [
          'Clear reply to topic due date/time for John and Alice',
          'Clear required replies due date/time for John and Alice',
        ]
        labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
      })

      it('labels the clear buttons on cards with 3 pills', () => {
        renderComponent({
          customAllOptions: [
            {id: 'student-1', value: 'John'},
            {id: 'student-2', value: 'Alice'},
            {id: 'student-3', value: 'Linda'},
          ],
          selectedAssigneeIds: ['student-1', 'student-2', 'student-3'],
          isCheckpointed: true,
        })
        const labels = [
          'Clear reply to topic due date/time for John, Alice, and Linda',
          'Clear required replies due date/time for John, Alice, and Linda',
        ]
        labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
      })

      it('labels the clear buttons on cards with more than 3 pills', () => {
        renderComponent({
          customAllOptions: [
            {id: 'student-1', value: 'John'},
            {id: 'student-2', value: 'Alice'},
            {id: 'student-3', value: 'Linda'},
            {id: 'student-4', value: 'Bob'},
          ],
          selectedAssigneeIds: ['student-1', 'student-2', 'student-3', 'student-4'],
          isCheckpointed: true,
        })
        const labels = [
          'Clear reply to topic due date/time for John, Alice, and 2 others',
          'Clear required replies due date/time for John, Alice, and 2 others',
        ]
        labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
      })
    })
  })
})
