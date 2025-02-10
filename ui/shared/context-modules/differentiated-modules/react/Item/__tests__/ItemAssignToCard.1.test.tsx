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
import userEvent from '@testing-library/user-event'
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
  window.ENV.HAS_GRADING_PERIODS = true
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
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders', () => {
    const {getByLabelText, getAllByLabelText, getByTestId, queryByRole} = renderComponent()
    expect(getByTestId('item-assign-to-card')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Delete'})).not.toBeInTheDocument()
    expect(getByLabelText('Due Date')).toBeInTheDocument()
    expect(getAllByLabelText('Time')).toHaveLength(3)
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
  })

  it('renders checkpoints fields and not Due Date', () => {
    // @ts-expect-error
    window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
    const {getByLabelText, getAllByLabelText} = renderComponent({
      isCheckpointed: true,
    })
    expect(getByLabelText('Reply to Topic Due Date')).toBeInTheDocument()
    expect(getByLabelText('Required Replies Due Date')).toBeInTheDocument()
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
    // rather than query for not due date, notice length remains 4
    expect(getAllByLabelText('Time')).toHaveLength(4)
  })

  describe('describes the render order', () => {
    it('renders the Due Date 1st from the top',  async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({due_at: undefined})
      const dateInput = getByLabelText('Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()
      await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('8:00 AM'))
    })

    it('renders the Reply to Topic Due Date 1st from the top', async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      // @ts-expect-error
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
      const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({
        due_at: undefined,
        isCheckpointed: true,
      })
      const dateInput = getByLabelText('Reply to Topic Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()

      await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('8:00 AM'))
      
    })

    it('renders the Required Replies Due Date 2nd from the top', async () => {
      window.ENV.DEFAULT_DUE_TIME = '08:00:00'
      // @ts-expect-error
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
      const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({
        due_at: undefined,
        isCheckpointed: true,
      })
      const dateInput = getByLabelText('Required Replies Due Date')
      fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})
      getByRole('option', {name: /10 november 2020/i}).click()

      await waitFor(() =>  expect(getAllByLabelText('Time')[1]).toHaveValue('8:00 AM'))
    })

    describe('isCheckpointed is true', () => {
      it('renders the Available From 3rd from the top', () => {
        // @ts-expect-error
        window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
        const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({
          due_at: undefined,
          isCheckpointed: true,
        })
        const dateInput = getByLabelText('Available from')
        fireEvent.change(dateInput, {target: {value: 'Nov 10, 2020'}})
        getByRole('option', {name: /10 november 2020/i}).click()
        expect(getAllByLabelText('Time')[2]).toHaveValue('12:00 AM')
      })

      it('renders the Available Until 4th from the top', async () => {
        // @ts-expect-error
        window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
        const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({
          due_at: undefined,
          isCheckpointed: true,
        })
        const dateInput = getByLabelText('Until')
        fireEvent.change(dateInput, {target: {value: 'Nov 14, 2020'}})
        getByRole('option', {name: /14 november 2020/i}).click()

        await waitFor(() => expect(getAllByLabelText('Time')[3]).toHaveValue('11:59 PM'))      
      })
    })
  })

  it('renders with the given dates', () => {
    const due_at = '2023-10-05T12:00:00Z'
    const unlock_at = '2023-10-03T12:00:00Z'
    const lock_at = '2023-10-10T12:00:00Z'
    const {getByLabelText} = renderComponent({due_at, unlock_at, lock_at})
    expect(getByLabelText('Due Date')).toHaveValue('Oct 5, 2023')
    expect(getByLabelText('Available from')).toHaveValue('Oct 3, 2023')
    expect(getByLabelText('Until')).toHaveValue('Oct 10, 2023')
  })

  it('does not render the due date input if removeDueDateInput is set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true})
    expect(queryByLabelText('Due Date')).not.toBeInTheDocument()
  })

  it('does not render the reply to topic input if removeDueDateInput is set & isCheckpointed is not set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true, isCheckpointed: false})
    expect(queryByLabelText('Reply to Topic Due Date')).not.toBeInTheDocument()
  })

  it('does not render the required replies input if removeDueDateInput is set & isCheckpointed is not set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true, isCheckpointed: false})
    expect(queryByLabelText('Required Replies Due Date')).not.toBeInTheDocument()
  })

  it('renders the delete button when onDelete is provided', () => {
    const onDelete = jest.fn()
    const {getByTestId} = renderComponent({onDelete})
    expect(getByTestId('delete-card-button')).toBeInTheDocument()
  })

  it('disables blueprint-locked date inputs', () => {
    const {getByLabelText, getAllByLabelText} = renderComponent({
      blueprintDateLocks: ['availability_dates', 'due_dates'],
    })
    expect(getByLabelText('Due Date')).toBeDisabled()
    expect(getByLabelText('Available from')).toBeDisabled()
    getAllByLabelText('Time').forEach(t => expect(t).toBeDisabled())
  })

  it('calls onDelete when delete button is clicked', () => {
    const onDelete = jest.fn()
    const {getByTestId} = renderComponent({onDelete})
    getByTestId('delete-card-button').click()
    expect(onDelete).toHaveBeenCalledWith('assign-to-card-001')
  })

  it('defaults to 11:59pm for due dates if has null due time on click', async () => {
    window.ENV.DEFAULT_DUE_TIME = undefined
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent()
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()

    await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('11:59 PM'))   
  })

  it('defaults to 11:59pm for due dates if has null due time on blur', async () => {
    window.ENV.DEFAULT_DUE_TIME = undefined
    const onCardDatesChangeMock = jest.fn()
    const {getByLabelText, findAllByLabelText} = renderComponent({
      onCardDatesChange: onCardDatesChangeMock,
    })
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    // userEvent causes Event Pooling issues, so I used fireEvent instead
    fireEvent.blur(dateInput, {target: {value: 'Nov 9, 2020'}})
    await waitFor(async () => {
      expect(onCardDatesChangeMock).toHaveBeenCalledWith(
        expect.any(String),
        'due_at',
        '2020-11-09T23:59:00.000Z',
      )
      expect((await findAllByLabelText('Time'))[0]).toHaveValue('11:59 PM')
    })
  })

  it('defaults to 11:59pm for due dates if has undefined due time', async () => {
    window.ENV.DEFAULT_DUE_TIME = undefined
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({due_at: undefined})
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('11:59 PM')) 
    
  })

  it('defaults to the default due time for due dates from ENV if has null due time', async () => {
    window.ENV.DEFAULT_DUE_TIME = '08:00:00'
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent()
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('8:00 AM')) 
    
  })

  it('defaults to the default due time for due dates from ENV if has undefined due time', async () => {
    window.ENV.DEFAULT_DUE_TIME = '08:00:00'
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({due_at: undefined})
    const dateInput = getByLabelText('Due Date')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    await waitFor(() => expect(getAllByLabelText('Time')[0]).toHaveValue('8:00 AM')) 
  })

  it('defaults to midnight for available from dates if it is null on click', () => {
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent()
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByLabelText('Time')[1]).toHaveValue('12:00 AM')
  })

  it('defaults to midnight for available from dates if it is null on blur', async () => {
    const onCardDatesChangeMock = jest.fn()
    const {getByLabelText, findAllByLabelText} = renderComponent({
      onCardDatesChange: onCardDatesChangeMock,
    })
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    // userEvent causes Event Pooling issues, so I used fireEvent instead
    fireEvent.blur(dateInput, {target: {value: 'Nov 9, 2020'}})
    await waitFor(async () => {
      expect(onCardDatesChangeMock).toHaveBeenCalledWith(
        expect.any(String),
        'unlock_at',
        '2020-11-09T00:00:00.000Z',
      )
      expect((await findAllByLabelText('Time'))[1]).toHaveValue('12:00 AM')
    })
  })

  it('defaults to midnight for available from dates if it is undefined', () => {
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({unlock_at: undefined})
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByLabelText('Time')[1]).toHaveValue('12:00 AM')
  })

  it('defaults to 11:59 PM for available until dates if it is null on click', async () => {
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent()
    const dateInput = getByLabelText('Until')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    await waitFor(() => expect(getAllByLabelText('Time')[2]).toHaveValue('11:59 PM')) 
  })

  it('defaults to 11:59 PM for available until dates if it is null on blur', async () => {
    const onCardDatesChangeMock = jest.fn()
    const {getByLabelText, findAllByLabelText} = renderComponent({
      onCardDatesChange: onCardDatesChangeMock,
    })
    const dateInput = getByLabelText('Until')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    // userEvent causes Event Pooling issues, so I used fireEvent instead
    fireEvent.blur(dateInput, {target: {value: 'Nov 9, 2020'}})
    await waitFor(async () => {
      expect(onCardDatesChangeMock).toHaveBeenCalledWith(
        expect.any(String),
        'lock_at',
        '2020-11-09T23:59:00.000Z',
      )
      expect((await findAllByLabelText('Time'))[2]).toHaveValue('11:59 PM')
    })
  })

  it('defaults to 11:59 PM for available until dates if it is undefined', async () => {
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent({lock_at: undefined})
    const dateInput = getByLabelText('Until')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    await waitFor(() => expect(getAllByLabelText('Time')[2]).toHaveValue('11:59 PM')) 
  })

  it('renders context module link', () => {
    renderComponent({contextModuleId: '2', contextModuleName: 'My fabulous module'})
    expect(screen.getByText('Inherited from')).toBeInTheDocument()
    const link = screen.getByRole('link', {name: 'My fabulous module'})
    expect(link).toHaveAttribute('href', '/courses/1/modules#2')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('show error when date field is blank and time field has value on blur', async () => {
    const {getAllByLabelText, getAllByText} = renderComponent()
    const timeInput = getAllByLabelText('Time')[0]

    await userEvent.type(timeInput, '3:30 PM')
    await userEvent.tab()

    await waitFor(async () => {
      expect(timeInput).toHaveValue('3:30 PM')
      expect(await getAllByText('Invalid date')[0]).toBeInTheDocument()
    })
  })

  it('clears date field and time field when date field is manually cleared on blur', async () => {
    const due_at = '2023-10-05T12:00:00Z'
    const {getAllByLabelText, getByLabelText} = renderComponent({due_at})
    const dateInput = getByLabelText('Due Date')
    const timeInput = getAllByLabelText('Time')[0]

    await userEvent.clear(dateInput)
    await userEvent.tab()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('')
      expect(timeInput).toHaveValue('')
    })
  })
})
