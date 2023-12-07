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
import {act, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import ItemAssignToTray, {type ItemAssignToTrayProps} from '../ItemAssignToTray'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'

describe('ItemAssignToTray', () => {
  const props: ItemAssignToTrayProps = {
    open: true,
    onClose: () => {},
    onDismiss: () => {},
    courseId: '1',
    itemName: 'Item Name',
    itemType: 'assignment',
    itemContentId: '23',
    pointsPossible: '10 pts',
    locale: 'en',
    timezone: 'UTC',
  }

  const SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections`
  const STUDENTS_URL = `api/v1/courses/${props.courseId}/users?enrollment_type=student`

  const OVERRIDES = [
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

  beforeEach(() => {
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
    // an assignment with valid dates and overrides
    fetchMock
      .get('/api/v1/courses/1/assignments/23/date_details', {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        overrides: OVERRIDES,
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
    fetchMock.get(STUDENTS_URL, STUDENTS_DATA).get(SECTIONS_URL, SECTIONS_DATA)
  })

  afterEach(() => {
    fetchMock.resetHistory()
    fetchMock.restore()
  })

  const renderComponent = (overrides: Partial<ItemAssignToTrayProps> = {}) =>
    render(<ItemAssignToTray {...props} {...overrides} />)

  it('renders', async () => {
    const {getByText, getByLabelText, findAllByTestId} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    // the tray is mocking an api response that makes 2 cards
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(2)
  })

  it('renders a quiz', () => {
    const {getByText} = renderComponent({itemType: 'quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
  })

  it('renders a new quiz', () => {
    const {getByText} = renderComponent({itemType: 'lti-quiz'})
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
    const {findAllByText} = renderComponent({itemContentId: '25', timezone: 'America/Denver'})

    const times = await findAllByText('Thursday, October 5, 2023 6:01 AM')
    expect(times).toHaveLength(2) // screenreader + visible message
  })

  it('renders times in the given locale', async () => {
    const {findAllByText} = renderComponent({
      itemContentId: '25',
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

  it('adds a card when add button is clicked', async () => {
    fetchMock.get(
      '/api/v1/courses/1/assignments/23/date_details',
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      }
    )
    const {getByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)
    act(() => getByRole('button', {name: 'Add'}).click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it.skip('deletes a card when delete button is clicked', async () => {
    const {getAllByRole, findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(2)
    act(() => getAllByRole('button', {name: 'Delete'})[1].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
  })

  it('calls onDismiss when the cancel button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Cancel'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('AssigneeSelector', () => {
    it.skip('shows existing overrides as selected options', async () => {
      const {findAllByTestId} = renderComponent()
      const sectionOverride = SECTIONS_DATA.find(
        section => section.id === OVERRIDES[0].course_section_id
      )!
      const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
      expect(selectedOptions).toHaveLength(2)
      expect(selectedOptions[0]).toHaveTextContent('Everyone else')
      expect(selectedOptions[1]).toHaveTextContent(sectionOverride?.name)
    })

    it('does not render everyone option if the assignment is set to overrides only', async () => {
      fetchMock.get(
        '/api/v1/courses/1/assignments/23/date_details',
        {
          id: '23',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          only_visible_to_overrides: true,
          overrides: OVERRIDES,
        },
        {
          overwriteRoutes: true,
        }
      )
      const {findAllByTestId, getAllByTestId} = renderComponent()
      const sectionOverride = SECTIONS_DATA.find(
        section => section.id === OVERRIDES[0].course_section_id
      )!
      const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
      const cards = getAllByTestId('item-assign-to-card')
      // only cards for overrides are rendered
      expect(cards).toHaveLength(OVERRIDES.length)
      expect(selectedOptions).toHaveLength(1)
      expect(selectedOptions[0]).toHaveTextContent(sectionOverride?.name)
    })

    it('renders everyone option if there are no overrides', async () => {
      fetchMock.get(
        '/api/v1/courses/1/assignments/23/date_details',
        {
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          overrides: [],
        },
        {
          overwriteRoutes: true,
        }
      )
      const {findAllByTestId} = renderComponent()
      const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
      expect(selectedOptions).toHaveLength(1)
      waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Everyone'))
    })

    it('renders everyone option if there are more than 1 card', async () => {
      fetchMock.get(
        '/api/v1/courses/1/assignments/23/date_details',
        {
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          overrides: [],
        },
        {
          overwriteRoutes: true,
        }
      )
      const {findAllByTestId, getByRole, getAllByTestId} = renderComponent()
      let selectedOptions = await findAllByTestId('assignee_selector_selected_option')
      expect(selectedOptions).toHaveLength(1)
      expect(selectedOptions[0]).toHaveTextContent('Everyone')
      act(() => getByRole('button', {name: 'Add'}).click())
      expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
      selectedOptions = getAllByTestId('assignee_selector_selected_option')
      expect(selectedOptions[0]).toHaveTextContent('Everyone else')
    })

    it('calls onDismiss when an error occurs while fetching data', async () => {
      fetchMock.getOnce(SECTIONS_URL, 500, {overwriteRoutes: true})
      const onDismiss = jest.fn()
      renderComponent({onDismiss})
      await waitFor(() => expect(onDismiss).toHaveBeenCalledTimes(1))
    })

    it.skip('does not allow to use the same assignee in more than one card', async () => {
      const sectionOverride = SECTIONS_DATA.find(
        section => section.id === OVERRIDES[0].course_section_id
      )!
      const otherSections = SECTIONS_DATA.filter(
        section => section.id !== OVERRIDES[0].course_section_id
      )!
      const {findAllByTestId, getAllByRole} = renderComponent()
      const assigneeSelectors = await findAllByTestId('assignee_selector')
      act(() => assigneeSelectors[0].click())
      const listOptions = getAllByRole('listitem')
      let sectionOption = listOptions.find(
        listitem => listitem.textContent === sectionOverride.name
      )
      // the option from the second card should not be available in the first card
      expect(sectionOption).toBeUndefined()
      otherSections.forEach(section => {
        sectionOption = listOptions.find(listitem => listitem.textContent === section.name)
        expect(sectionOption).not.toBeUndefined()
      })
    })
  })
})
