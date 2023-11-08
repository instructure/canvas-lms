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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import ItemAssignToTray, {ItemAssignToTrayProps} from '../ItemAssignToTray'

export type UnknownSubset<T> = {
  [K in keyof T]?: T[K]
}

describe('ItemAssignToTray', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV ||= {}
    ENV.VALID_DATE_RANGE = {
      start_at: {date: '2023-08-20T12:00:00Z', date_context: 'course'},
      end_at: {date: '2023-12-30T12:00:00Z', date_context: 'course'},
    }
    ENV.HAS_GRADING_PERIODS = false
    // @ts-expect-error
    ENV.SECTION_LIST = [{id: '4'}, {id: '5'}]
    ENV.POST_TO_SIS = false
    ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = false

    fetchMock
      // an assignment with valid dates and overrides
      .get('/api/v1/courses/1/assignments/23/date_details', {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        overrides: [
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
          {
            id: '3',
            assignment_id: '23',
            title: 'Neal and John',
            due_at: '2023-10-03T12:00:00Z',
            all_day: false,
            all_day_date: '2023-10-03',
            unlock_at: null,
            lock_at: null,
            course_section_id: '5',
          },
        ],
      })
      // an assignment with invalid dates
      .get('/api/v1/courses/1/assignments/24/date_details', {
        id: '24',
        due_at: '2023-09-30T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        overrides: [],
      })
      // an assignment with valid dates and no overrides
      .get('/api/v1/courses/1/assignments/25/date_details', {
        id: '25',
        due_at: '2023-10-05T12:01:00Z',
        unlock_at: null,
        lock_at: null,
        only_visible_to_overrides: false,
        overrides: [],
      })
      .get('/api/v1/courses/1/quizzes/23/date_details', {})
  })

  afterEach(() => {
    fetchMock.resetHistory()
  })

  const props: ItemAssignToTrayProps = {
    open: true,
    onClose: () => {},
    onDismiss: () => {},
    onSave: () => {},
    courseId: '1',
    moduleItemId: '2',
    moduleItemName: 'Item Name',
    moduleItemType: 'assignment',
    moduleItemContentType: 'assignment',
    moduleItemContentId: '23',
    pointsPossible: '10 pts',
    locale: 'en',
    timezone: 'UTC',
  }

  const renderComponent = (overrides: UnknownSubset<ItemAssignToTrayProps> = {}) =>
    render(<ItemAssignToTray {...props} {...overrides} />)

  it('renders', async () => {
    const {getByText, getByLabelText, findAllByTestId} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    // the tray is mocking an api response that makes 3 cards
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
  })

  it('renders a quiz', () => {
    const {getByText} = renderComponent({moduleItemType: 'quiz', moduleItemContentType: 'quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
  })

  it('renders a new quiz', () => {
    const {getByText} = renderComponent({moduleItemType: 'lti-quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
  })

  it('renders with no points', () => {
    const {getByText, queryByText, getByLabelText} = renderComponent({pointsPossible: undefined})
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment')).toBeInTheDocument()
    expect(queryByText('pts')).not.toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
  })

  it('renders times in the given timezone', async () => {
    const {findAllByText} = renderComponent({moduleItemContentId: '25', timezone: 'America/Denver'})

    const times = await findAllByText('Thursday, October 5, 2023 6:01 AM')
    expect(times).toHaveLength(2) // screenreader + visible message
  })

  it('renders times in the given locale', async () => {
    const {findAllByText} = renderComponent({
      moduleItemContentId: '25',
      locale: 'en-GB',
      timezone: 'America/Denver',
    })
    const times = await findAllByText('Thursday, 5 October 2023 06:01')
    expect(times).toHaveLength(2) // screenreader + visible message
  })

  it('calls onDismiss when close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Close'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onSave when save button is clicked', () => {
    const onSave = jest.fn()
    const {getByRole} = renderComponent({onSave})
    getByRole('button', {name: 'Save'}).click()
    expect(onSave).toHaveBeenCalled()
  })

  it('adds a card when add button is clicked', async () => {
    const {getByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
    getByRole('button', {name: 'Add'}).click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(4)
  })

  it('deletes a card when delete button is clicked', async () => {
    const {getAllByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
    getAllByRole('button', {name: 'Delete'})[1].click()
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it('calls onDismiss when the cancel button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Cancel'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls onSave when the Save buton is clicked', () => {
    const onSave = jest.fn()
    const {getByRole} = renderComponent({onSave})
    getByRole('button', {name: 'Save'}).click()
    expect(onSave).toHaveBeenCalled()
  })

  it('Save does not call onSave when a card is invalid', async () => {
    const onSave = jest.fn()
    const {getAllByTestId, getByRole, getByText} = renderComponent({
      onSave,
      moduleItemContentId: '24',
    })
    await waitFor(() => {
      expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
    })
    const savebtn = getByRole('button', {name: 'Save'})

    savebtn.click()
    expect(onSave).not.toHaveBeenCalled()
    savebtn.focus()
    expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
  })
})
