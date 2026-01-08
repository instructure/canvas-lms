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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeEnv from '@canvas/test-utils/fakeENV'

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

describe('ItemAssignToCard - Available From Defaults', () => {
  beforeAll(() => {
    server.listen()
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  afterAll(() => server.close())

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
    )
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    server.resetHandlers()
    fakeEnv.teardown()
  })

  it('defaults to midnight for available from dates if it is null on click', () => {
    const {getByLabelText, getByRole, getAllByLabelText} = renderComponent()
    const dateInput = getByLabelText('Available from')
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    getByRole('option', {name: /10 november 2020/i}).click()
    expect(getAllByLabelText('Time')[1]).toHaveValue('12:00 AM')
  })

  it('defaults to midnight for available from dates if it is null on blur', async () => {
    const onCardDatesChangeMock = vi.fn()
    const {getByLabelText, findAllByLabelText} = renderComponent({
      onCardDatesChange: onCardDatesChangeMock,
    })
    const dateInput = getByLabelText('Available from')
    // Clear mock calls from initial render
    onCardDatesChangeMock.mockClear()
    fireEvent.change(dateInput, {target: {value: 'Nov 9, 2020'}})
    // userEvent causes Event Pooling issues, so I used fireEvent instead
    fireEvent.blur(dateInput, {target: {value: 'Nov 9, 2020'}})
    await waitFor(async () => {
      // Check if the mock was called with the correct arguments at any point
      const unlockAtCalls = onCardDatesChangeMock.mock.calls.filter(call => call[1] === 'unlock_at')
      expect(unlockAtCalls.length).toBeGreaterThan(0)
      expect(unlockAtCalls[unlockAtCalls.length - 1]).toEqual([
        expect.any(String),
        'unlock_at',
        '2020-11-09T00:00:00.000Z',
      ])
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
})
