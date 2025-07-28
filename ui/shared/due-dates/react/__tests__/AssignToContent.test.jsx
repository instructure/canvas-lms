/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, act, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignToContent from '../AssignToContent'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fetchMock from 'fetch-mock'

const SECTIONS_DATA = [
  {id: '1', course_id: '1', name: 'Course 1', start_at: null, end_at: null},
  {id: '2', course_id: '1', name: 'Section A', start_at: null, end_at: null},
]

const COURSE_ID = 1
const ASSIGNMENT_ID = '1'

describe('AssignToContent', () => {
  const assignmentcollection = new AssignmentOverrideCollection([
    {
      id: '100',
      assignment_id: '5',
      title: 'Section A',
      due_at: '2024-01-17T23:59:59-07:00',
      all_day: true,
      all_day_date: '2024-01-17',
      unlock_at: null,
      lock_at: null,
      course_section_id: '2',
      due_at_overridden: true,
      unlock_at_overridden: true,
      lock_at_overridden: true,
    },
  ])

  const props = {
    onSync: () => {},
    importantDates: false,
    getAssignmentName: () => 'First Assignment',
    assignmentId: ASSIGNMENT_ID,
    type: 'assignment',
    getPointsPossible: () => '10',
    overrides: assignmentcollection.models.map(model => model.toJSON().assignment_override),
    defaultSectionId: 0,
  }

  const SECTIONS_URL = `/api/v1/courses/${COURSE_ID}/sections?per_page=100`
  const DATE_DETAILS = `/api/v1/courses/${COURSE_ID}/assignments/${ASSIGNMENT_ID}/date_details?per_page=100`
  const SETTINGS_URL = `/api/v1/courses/${COURSE_ID}/settings`

  beforeAll(() => {
    window.ENV ||= {}
    ENV.COURSE_ID = COURSE_ID
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA).get(DATE_DETAILS, {}).get(SETTINGS_URL, {})
    queryClient.setQueryData(['students', COURSE_ID, {per_page: 100}], [])
  })

  afterEach(() => {
    fetchMock.resetHistory()
    fetchMock.restore()
  })

  const setUp = (propOverrides = {}) =>
    render(
      <MockedQueryProvider>
        <AssignToContent {...props} {...propOverrides} />
      </MockedQueryProvider>,
    )

  it('renders', () => {
    const {getAllByText} = setUp()
    expect(getAllByText('Assign To')[0]).toBeInTheDocument()
  })

  it('adds a card when add button is clicked', async () => {
    const {getAllByRole, findAllByTestId, getAllByTestId} = setUp()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)
    act(() => getAllByRole('button', {name: 'Assign To'})[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it("adds a new card even if there's no cards", async () => {
    setUp({overrides: []})
    const cards = await screen.queryAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(0)
    await userEvent.click(screen.getAllByTestId('add-card')[0])
    expect(screen.getAllByTestId('item-assign-to-card')).toHaveLength(1)
  })

  describe('pending changes', () => {
    const addAssignee = async (getByTestId, findByTestId, findByText) => {
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())
    }

    // TODO: fix this test, fails when run with suite but passes when run alone
    it.skip('highlights card if it has changes', async () => {
      const {getByTestId, findByTestId, findByText} = setUp()
      await addAssignee(getByTestId, findByTestId, findByText)
      expect(getByTestId('highlighted_card')).toBeInTheDocument()
    })
  })

  describe('in a paced course', () => {
    beforeEach(() => {
      ENV.IN_PACED_COURSE = true
    })

    afterEach(() => {
      ENV.IN_PACED_COURSE = false
    })

    it('shows the course pacing notice', () => {
      const {getByTestId} = setUp()
      expect(getByTestId('CoursePacingNotice')).toBeInTheDocument()
    })

    it('does not fetch assignee options', () => {
      setUp()
      expect(fetchMock.calls(SECTIONS_URL)).toHaveLength(0)
    })
  })

  describe('important dates', () => {
    beforeAll(() => {
      global.ENV = {
        ...global.ENV,
        K5_SUBJECT_COURSE: true,
      }
    })

    it('renders the option for assignment items', () => {
      const {queryByTestId} = setUp({type: 'assignment'})
      expect(queryByTestId('important_dates')).toBeInTheDocument()
    })

    it('renders the option for discussion items', () => {
      const {queryByTestId} = setUp({type: 'discussion'})
      expect(queryByTestId('important_dates')).toBeInTheDocument()
    })

    it('renders the option for quiz items', () => {
      const {queryByTestId} = setUp({type: 'quiz'})
      expect(queryByTestId('important_dates')).toBeInTheDocument()
    })

    it('does not render the option for non-supported items', () => {
      const {queryByTestId} = setUp({type: 'module'})

      expect(queryByTestId('important_dates')).not.toBeInTheDocument()
    })

    describe('if supportDueDates is false', () => {
      it('does not render the option for assignment items', () => {
        const {queryByTestId} = setUp({type: 'assignment', supportDueDates: false})
        expect(queryByTestId('important_dates')).not.toBeInTheDocument()
      })

      it('does not render the option for discussion items', () => {
        const {queryByTestId} = setUp({type: 'discussion', supportDueDates: false})
        expect(queryByTestId('important_dates')).not.toBeInTheDocument()
      })

      it('does not render the option for quiz items', () => {
        const {queryByTestId} = setUp({type: 'quiz', supportDueDates: false})
        expect(queryByTestId('important_dates')).not.toBeInTheDocument()
      })

      it('does not render the option for non-supported items', () => {
        const {queryByTestId} = setUp({type: 'module', supportDueDates: false})

        expect(queryByTestId('important_dates')).not.toBeInTheDocument()
      })
    })

    it('calls onSync with the importantDates flag when checking/unchecking the option', () => {
      const onSyncMock = jest.fn()
      const {getByTestId} = setUp({onSync: onSyncMock})

      getByTestId('important_dates').click()
      expect(onSyncMock).toHaveBeenCalledWith(undefined, true)

      getByTestId('important_dates').click()
      expect(onSyncMock).toHaveBeenCalledWith(undefined, false)
    })

    it('disables the importantDates check when no due dates are set', () => {
      const override = [assignmentcollection.models[0]]
      override[0].set('due_at', '')
      const {getByTestId} = setUp({overrides: override})

      expect(getByTestId('important_dates')).toBeDisabled()
    })
  })
})
