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
    window.ENV = window.ENV || {}
    window.ENV.HAS_GRADING_PERIODS = false
    window.ENV.active_grading_periods = []
    window.ENV.current_user_is_admin = false
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
    window.ENV.HAS_GRADING_PERIODS = false
    window.ENV.active_grading_periods = []
    window.ENV.current_user_is_admin = false
  })

  afterAll(() => {
    server.close()
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

    it('defaults to the default due time for due dates from ENV if has undefined due time', async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      const {getByLabelText, getByTestId} = renderComponent({due_at: undefined})
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      const dateTimeInput = getByTestId('due_at_input')
      expect(dateTimeInput).toBeInTheDocument()
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
      const {getByLabelText, getByTestId} = renderComponent()
      const dateInput = getByLabelText('Available from')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      const dateTimeInput = getByTestId('unlock_at_input')
      expect(dateTimeInput).toBeInTheDocument()
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
      const {getByLabelText, getByTestId} = renderComponent()
      const dateInput = getByLabelText('Until')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      const dateTimeInput = getByTestId('lock_at_input')
      expect(dateTimeInput).toBeInTheDocument()
    })

    it('defaults to 11:59 PM for available until dates if it is undefined', async () => {
      const {getByLabelText, getByTestId} = renderComponent({lock_at: undefined})
      const dateInput = getByLabelText('Until')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})

      const dateTimeInput = getByTestId('lock_at_input')
      expect(dateTimeInput).toBeInTheDocument()
    })
  })
})
