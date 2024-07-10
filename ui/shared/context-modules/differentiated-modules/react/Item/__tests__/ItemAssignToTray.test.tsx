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
import {act, fireEvent, render, waitFor, screen} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import ItemAssignToTray, {type ItemAssignToTrayProps} from '../ItemAssignToTray'
import {
  SECTIONS_DATA,
  STUDENTS_DATA,
  FIRST_GROUP_CATEGORY_DATA,
  SECOND_GROUP_CATEGORY_DATA,
  ADHOC_WITHOUT_STUDENTS,
} from '../../__tests__/mocks'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

// Mock the showFlashError that occurs when an itemType is not supported.
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  ...jest.requireActual('@canvas/alerts/react/FlashAlert'),
  showFlashError: jest.fn(() => jest.fn()),
}))

describe('ItemAssignToTray', () => {
  let originalLocation = window.location
  const props: ItemAssignToTrayProps = {
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

  const FIRST_GROUP_CATEGORY_ID = '2'
  const SECOND_GROUP_CATEGORY_ID = '3'
  const FIRST_GROUP_CATEGORY_URL = `/api/v1/group_categories/${FIRST_GROUP_CATEGORY_ID}/groups?per_page=100`
  const SECOND_GROUP_CATEGORY_URL = `/api/v1/group_categories/${SECOND_GROUP_CATEGORY_ID}/groups?per_page=100`
  const SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?per_page=\d+/
  const STUDENTS_URL = /\/api\/v1\/courses\/.+\/users\?per_page=\d+&enrollment_type=student/
  const OVERRIDES_URL = '/api/v1/courses/1/assignments/23/date_details?per_page=100'

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

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

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
    originalLocation = window.location
    // @ts-expect-error
    delete window.location
    window.location = {...originalLocation, reload: jest.fn()}
    // an assignment with valid dates and overrides
    fetchMock.get('/api/v1/courses/1/settings', {conditional_release: false})
    fetchMock
      .get(OVERRIDES_URL, {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: OVERRIDES,
      })
      // an assignment with invalid dates
      .get('/api/v1/courses/1/assignments/24/date_details?per_page=100', {
        id: '24',
        due_at: '2023-09-30T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      })
      // an assignment with valid dates and no overrides
      .get('/api/v1/courses/1/assignments/25/date_details?per_page=100', {
        id: '25',
        due_at: '2023-10-05T12:01:00Z',
        unlock_at: null,
        lock_at: null,
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      })
      .get('/api/v1/courses/1/quizzes/23/date_details?per_page=100', {})
      .get('/api/v1/courses/1/discussion_topics/23/date_details?per_page=100', {})
      .get('/api/v1/courses/1/pages/23/date_details?per_page=100', {})
    fetchMock
      .get(STUDENTS_URL, STUDENTS_DATA)
      .get(SECTIONS_URL, SECTIONS_DATA)
      .get(FIRST_GROUP_CATEGORY_URL, FIRST_GROUP_CATEGORY_DATA)
      .get(SECOND_GROUP_CATEGORY_URL, SECOND_GROUP_CATEGORY_DATA)
  })

  afterEach(() => {
    window.location = originalLocation
    fetchMock.resetHistory()
    fetchMock.restore()
  })

  const renderComponent = (overrides: Partial<ItemAssignToTrayProps> = {}) =>
    render(<ItemAssignToTray {...props} {...overrides} />)

  it('renders', async () => {
    const {getByTestId, getByText, getByLabelText, findAllByTestId} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    // the tray is mocking an api response that makes 2 cards
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(2)
    const icon = getByTestId('icon-assignment')
    expect(icon).toBeInTheDocument()
  })

  it('renders a quiz', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'quiz', iconType: 'quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-quiz')
    expect(icon).toBeInTheDocument()
  })

  it('renders a new quiz', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'lti-quiz', iconType: 'lti-quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-lti-quiz')
    expect(icon).toBeInTheDocument()
  })

  it('renders a discussion', () => {
    const {getByTestId, getByText} = renderComponent({
      itemType: 'discussion',
      iconType: 'discussion',
    })
    expect(getByText('Discussion | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-discussion')
    expect(icon).toBeInTheDocument()
  })

  it('renders a page', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'page', iconType: 'page'})
    expect(getByText('Page | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-page')
    expect(icon).toBeInTheDocument()
  })

  it('renders Save button', () => {
    const {getByText} = renderComponent({useApplyButton: false})
    expect(getByText('Save')).toBeInTheDocument()
  })

  it("renders Save button when it hasn't been passed", () => {
    const {getByText} = renderComponent()
    expect(getByText('Save')).toBeInTheDocument()
  })

  it('renders Apply button', () => {
    const {getByText} = renderComponent({useApplyButton: true})
    expect(getByText('Apply')).toBeInTheDocument()
  })

  describe('pointsPossible display', () => {
    it('does not render points display if undefined', () => {
      const {getByText, queryByText, getByLabelText} = renderComponent({pointsPossible: undefined})
      expect(getByText('Item Name')).toBeInTheDocument()
      expect(getByText('Assignment')).toBeInTheDocument()
      expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
      expect(queryByText('pts')).not.toBeInTheDocument()
      expect(queryByText('pt')).not.toBeInTheDocument()
    })

    it('renders with 0 points', () => {
      const {getByText} = renderComponent({pointsPossible: 0})
      expect(getByText('Assignment | 0 pts')).toBeInTheDocument()
    })

    it('renders singular with 1 point', () => {
      const {getByText} = renderComponent({pointsPossible: 1})
      expect(getByText('Assignment | 1 pt')).toBeInTheDocument()
    })

    it('renders fractional points', () => {
      const {getByText} = renderComponent({pointsPossible: 100.5})
      expect(getByText('Assignment | 100.5 pts')).toBeInTheDocument()
    })

    it('renders a normal amount of points', () => {
      const {getByText} = renderComponent({pointsPossible: 25})
      expect(getByText('Assignment | 25 pts')).toBeInTheDocument()
    })
  })

  it('calls onClose when close button is clicked', () => {
    const onClose = jest.fn()
    const {getByRole} = renderComponent({onClose})
    getByRole('button', {name: 'Close'}).click()
    expect(onClose).toHaveBeenCalled()
  })

  it('adds a card when add button is clicked', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
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

  it('renders blueprint locking info when there are locked dates', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      blueprint_date_locks: ['availability_dates'],
    })
    const {getAllByText, getByTestId} = renderComponent({itemContentId: '31'})
    // wait for the cards to render
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0]
    ).toBeInTheDocument()
  })

  it('renders blueprint locking info when there are locked dates and default cards', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      blueprint_date_locks: ['availability_dates'],
    })
    const {getAllByText, findAllByTestId} = renderComponent({
      itemContentId: '31',
      defaultCards: [
        {
          defaultOptions: ['everyone'],
          key: 'key-card-0',
          isValid: true,
          highlightCard: false,
          hasAssignees: true,
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          selectedAssigneeIds: ['everyone'],
        },
      ],
    })
    await findAllByTestId('item-assign-to-card')
    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0]
    ).toBeInTheDocument()
  })

  it('does not render blueprint locking info when locked with unlocked due dates', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      blueprint_date_locks: [],
    })
    const {getByTestId, queryByText} = renderComponent({itemContentId: '31'})

    // wait for the cards to render
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    await expect(queryByText('Locked:')).not.toBeInTheDocument()
  })

  it('disables add button if there are blueprint-locked dates', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      blueprint_date_locks: ['availability_dates'],
    })
    const {getByTestId, findAllByText} = renderComponent({itemContentId: '31'})
    await findAllByText('Locked:')
    expect(getByTestId('add-card')).toBeDisabled()
  })

  it('disables add button if there are blueprint-locked dates and default cards', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      blueprint_date_locks: ['availability_dates'],
    })
    const {getByTestId, findAllByText} = renderComponent({
      itemContentId: '31',
      defaultCards: [
        {
          defaultOptions: ['everyone'],
          key: 'key-card-0',
          isValid: true,
          highlightCard: false,
          hasAssignees: true,
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          selectedAssigneeIds: ['everyone'],
        },
      ],
    })
    await findAllByText('Locked:')
    expect(getByTestId('add-card')).toBeDisabled()
  })

  it('calls onDismiss when the cancel button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Cancel'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('fetches assignee options when defaultCards are passed', () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      }
    )
    renderComponent({defaultCards: []})
    expect(fetchMock.calls(OVERRIDES_URL).length).toBe(1)
  })

  it('calls customAddCard if passed when a card is added', () => {
    const customAddCard = jest.fn()
    const {getByRole} = renderComponent({onAddCard: customAddCard})

    act(() => getByRole('button', {name: 'Add'}).click())
    expect(customAddCard).toHaveBeenCalled()
  })

  describe('AssigneeSelector', () => {
    it('does not render everyone option if the assignment is set to overrides only', async () => {
      fetchMock.get(
        OVERRIDES_URL,
        {
          id: '23',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          only_visible_to_overrides: true,
          visible_to_everyone: false,
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
        OVERRIDES_URL,
        {
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          visible_to_everyone: true,
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

    it('renders everyone option for item with course and module overrides', async () => {
      fetchMock.get(
        OVERRIDES_URL,
        {
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: true,
          visible_to_everyone: true,
          overrides: [
            {
              due_at: null,
              id: undefined,
              lock_at: null,
              course_id: 1,
              unlock_at: null,
            },
            {
              due_at: null,
              id: undefined,
              lock_at: null,
              context_module_id: 1,
              unlock_at: null,
            },
          ],
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

    it('renders mastery paths option for noop 1 overrides', async () => {
      fetchMock.get(
        '/api/v1/courses/1/settings',
        {conditional_release: true},
        {overwriteRoutes: true}
      )
      fetchMock.get(
        OVERRIDES_URL,
        {
          overrides: [
            {
              due_at: null,
              id: undefined,
              lock_at: null,
              noop_id: 1,
              unlock_at: null,
            },
          ],
        },
        {overwriteRoutes: true}
      )
      const {findAllByTestId} = renderComponent()
      const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
      expect(selectedOptions).toHaveLength(1)
      waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Mastery Paths'))
    })

    it('calls onDismiss when an error occurs while fetching data', async () => {
      fetchMock.getOnce(SECTIONS_URL, 500, {overwriteRoutes: true})
      const onDismiss = jest.fn()
      renderComponent({onDismiss})
      await waitFor(() => expect(onDismiss).toHaveBeenCalledTimes(1))
    })
  })
  describe('on save', () => {
    const DATE_DETAILS = `/api/v1/courses/${props.courseId}/assignments/${props.itemContentId}/date_details`
    const DATE_DETAILS_OBJ = {
      id: '23',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
    }

    beforeEach(() => {
      fetchMock.get(OVERRIDES_URL, DATE_DETAILS_OBJ, {
        overwriteRoutes: true,
      })
      fetchMock.put(DATE_DETAILS, {})
    })

    it('creates new assignment overrides', async () => {
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())

      getByRole('button', {name: 'Save'}).click()
      expect((await findAllByText(`${props.itemName} updated`))[0]).toBeInTheDocument()
      const requestBody = fetchMock.lastOptions(DATE_DETAILS)?.body
      const {id, overrides, only_visible_to_overrides, visible_to_everyone, ...payloadValues} =
        DATE_DETAILS_OBJ
      const expectedPayload = JSON.stringify({
        ...payloadValues,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        only_visible_to_overrides,
        assignment_overrides: [
          {
            course_section_id: SECTIONS_DATA[0].id,
            ...payloadValues,
            unassign_item: false,
          },
        ],
      })
      expect(requestBody).toEqual(expectedPayload)
    })

    it('calls onDismiss after saving', async () => {
      const onDismissMock = jest.fn()
      const {findAllByLabelText, getByRole, findAllByText} = renderComponent({
        onDismiss: onDismissMock,
      })
      const dateInput = await findAllByLabelText('Due Date')
      fireEvent.change(dateInput[0], {target: {value: 'Oct 2, 2023'}})
      getByRole('button', {name: 'Save'}).click()
      expect((await findAllByText(`${props.itemName} updated`))[0]).toBeInTheDocument()
      await waitFor(() => {
        expect(onDismissMock).toHaveBeenCalled()
      })
    })

    it('Save does not persist changes when a card is invalid', async () => {
      const onDismissMock = jest.fn()
      const {getAllByTestId, getByRole, getByText} = renderComponent({
        itemContentId: '24',
        onDismiss: onDismissMock,
      })
      await waitFor(() => {
        expect(getAllByTestId('item-assign-to-card')).toHaveLength(1)
      })
      const savebtn = getByRole('button', {name: 'Save'})

      savebtn.click()
      expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
      expect(
        fetchMock.lastOptions('/api/v1/courses/1/assignments/24/date_details?per_page=100')?.method
      ).toBe('GET')
      expect(onDismissMock).not.toHaveBeenCalled()
    })

    it('reloads the page after saving', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByTestId} = renderComponent()
      const save = getByTestId('differentiated_modules_save_button')
      await user.click(save)
      await waitFor(() => {
        expect(window.location.reload).toHaveBeenCalled()
      })
    })

    it('does not reload the page after saving if onSave is passed', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const onSave = jest.fn()
      const {getByTestId} = renderComponent({onSave})
      const save = getByTestId('differentiated_modules_save_button')
      await user.click(save)
      await waitFor(() => {
        expect(onSave).toHaveBeenCalled()
      })
      expect(window.location.reload).not.toHaveBeenCalled()
    })

    it('shows loading spinner while saving', async () => {
      fetchMock.put(DATE_DETAILS, {}, {overwriteRoutes: true, delay: 500})
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByTestId} = renderComponent()
      const save = getByTestId('differentiated_modules_save_button')
      await user.click(save)
      expect(getByTestId('cards-loading')).toBeInTheDocument()
    })

    it('does not show cards for ADHOC override with no students', async () => {
      fetchMock.get(OVERRIDES_URL, ADHOC_WITHOUT_STUDENTS, {
        overwriteRoutes: true,
      })
      const {findAllByTestId} = renderComponent()
      const cards = await findAllByTestId('item-assign-to-card')
      expect(cards).toHaveLength(1)
    })

    it('does not include ADHOC overrides without students when saving', async () => {
      fetchMock.get(OVERRIDES_URL, ADHOC_WITHOUT_STUDENTS, {
        overwriteRoutes: true,
      })
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {findByTestId, findAllByText, findAllByTestId} = renderComponent()
      const cards = await findAllByTestId('item-assign-to-card')
      // renders only 1 valid card
      expect(cards).toHaveLength(1)
      const save = await findByTestId('differentiated_modules_save_button')
      await user.click(save)
      expect((await findAllByText(`${props.itemName} updated`))[0]).toBeInTheDocument()
      const requestBody = JSON.parse(fetchMock.lastOptions(DATE_DETAILS)?.body)
      // filters out invalid overrides
      expect(requestBody.assignment_overrides).toHaveLength(1)
    })
  })

  describe('Module Overrides', () => {
    const DATE_DETAILS_WITHOUT_OVERRIDES = {
      id: '23',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      overrides: [
        {
          id: '3',
          assignment_id: '23',
          title: 'Sally and Wally',
          due_at: '2023-10-02T12:00:00Z',
          all_day: false,
          all_day_date: '2023-10-02',
          unlock_at: null,
          lock_at: null,
          course_section_id: '4',
          context_module_id: 1,
          context_module_name: 'Test Module',
        },
      ],
    }

    const DATE_DETAILS_WITH_OVERRIDES = {
      ...DATE_DETAILS_WITHOUT_OVERRIDES,
      overrides: [...OVERRIDES, ...DATE_DETAILS_WITHOUT_OVERRIDES.overrides],
    }

    it('shows module cards if they are not overridden', async () => {
      fetchMock.get(OVERRIDES_URL, DATE_DETAILS_WITHOUT_OVERRIDES, {
        overwriteRoutes: true,
      })
      const {getByText, findAllByTestId, getByTestId} = renderComponent()
      const cards = await findAllByTestId('item-assign-to-card')
      expect(getByText('Inherited from')).toBeInTheDocument()
      expect(getByTestId('context-module-text')).toBeInTheDocument()
      expect(cards).toHaveLength(1)
    })

    it('does not show overridden module cards', async () => {
      fetchMock.get(OVERRIDES_URL, DATE_DETAILS_WITH_OVERRIDES, {
        overwriteRoutes: true,
      })
      const {queryByText, findAllByTestId, queryByTestId} = renderComponent()
      const cards = await findAllByTestId('item-assign-to-card')
      expect(queryByText('Inherited from')).not.toBeInTheDocument()
      expect(queryByTestId('context-module-text')).not.toBeInTheDocument()
      expect(cards).toHaveLength(1)
    })
  })

  it('focuses on the add button when deleting a card', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getByTestId} = renderComponent()

    const deleteButton = (await findAllByTestId('delete-card-button'))[1]
    await user.click(deleteButton)

    const addButton = getByTestId('add-card')
    expect(addButton).toHaveFocus()
  })

  it("focuses on the newly-created card's delete button when adding a card", async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getByTestId} = renderComponent()

    // wait for the cards to render
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    const addButton = getByTestId('add-card')
    await user.click(addButton)
    const deleteButtons = await findAllByTestId('delete-card-button')
    expect(deleteButtons[deleteButtons.length - 1].closest('button')).toHaveFocus()
  })

  describe('Student Groups', () => {
    const payload = {
      id: '23',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      group_category_id: FIRST_GROUP_CATEGORY_ID,
      visible_to_everyone: true,
      overrides: [],
    }

    it('displays student groups if the assignmet is a group assignment', async () => {
      fetchMock.get(OVERRIDES_URL, payload, {
        overwriteRoutes: true,
      })
      const {findByText, findByTestId, getByText} = renderComponent()
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      await findByText(FIRST_GROUP_CATEGORY_DATA[0].name)
      FIRST_GROUP_CATEGORY_DATA.forEach(group => {
        expect(getByText(group.name)).toBeInTheDocument()
      })
    })

    it('refreshes the group options if the group category is overridden', async () => {
      fetchMock.get(OVERRIDES_URL, payload, {
        overwriteRoutes: true,
      })
      const {findByText, findByTestId, getByText, queryByText, rerender} = renderComponent()
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      await findByText(FIRST_GROUP_CATEGORY_DATA[0].name)
      SECOND_GROUP_CATEGORY_DATA.forEach(group => {
        expect(queryByText(group.name)).not.toBeInTheDocument()
      })
      rerender(<ItemAssignToTray {...props} defaultGroupCategoryId={SECOND_GROUP_CATEGORY_ID} />)
      await findByText(SECOND_GROUP_CATEGORY_DATA[0].name)
      SECOND_GROUP_CATEGORY_DATA.forEach(group => {
        expect(getByText(group.name)).toBeInTheDocument()
      })
    })
  })

  it('fetches overrides and assignee options only once', async () => {
    const urls = [STUDENTS_URL, SECTIONS_URL, OVERRIDES_URL]
    const {rerender, findAllByTestId} = renderComponent()
    const assigneeSelectors = await findAllByTestId('assignee_selector')
    expect(assigneeSelectors[0]).toBeInTheDocument()
    urls.forEach(url => expect(fetchMock.calls(url).length).toBe(1))
    rerender(<ItemAssignToTray {...props} open={false} />)
    rerender(<ItemAssignToTray {...props} open={true} />)
    urls.forEach(url => expect(fetchMock.calls(url).length).toBe(1))
  })

  describe('in a paced course', () => {
    beforeEach(() => {
      ENV.IN_PACED_COURSE = true
    })

    afterEach(() => {
      ENV.IN_PACED_COURSE = false
    })

    it('shows the course pacing notice', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('CoursePacingNotice')).toBeInTheDocument()
    })

    it('does not request existing overrides', () => {
      renderComponent()
      expect(fetchMock.calls(OVERRIDES_URL).length).toBe(0)
    })

    it('does not fetch assignee options', () => {
      renderComponent()
      expect(fetchMock.calls(STUDENTS_URL).length).toBe(0)
      expect(fetchMock.calls(SECTIONS_URL).length).toBe(0)
    })
  })

  describe('required due dates', () => {
    beforeEach(() => {
      global.ENV = {
        ...global.ENV,
        DUE_DATE_REQUIRED_FOR_ACCOUNT: true,
      }
    })

    it('validates if required due dates are set before applying changes', async () => {
      const {getByTestId, findAllByTestId, getByText, getAllByText} = renderComponent({
        postToSIS: true,
      })
      // wait until the cards are loaded
      const cards = await findAllByTestId('item-assign-to-card')
      expect(cards[0]).toBeInTheDocument()

      const addCardBtn = getByTestId('add-card')
      act(() => addCardBtn.click())

      getByTestId('differentiated_modules_save_button').click()

      expect(getAllByText('Please add a due date')[0]).toBeInTheDocument()
      expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
      // tray stays open
      expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    })
  })
})
