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
import {render, act} from '@testing-library/react'
import DifferentiatedModulesSection from '../DifferentiatedModulesSection'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import fetchMock from 'fetch-mock'

const SECTIONS_DATA = [
  {id: '1', course_id: '1', name: 'Course 1', start_at: null, end_at: null},
  {id: '2', course_id: '1', name: 'Section A', start_at: null, end_at: null},
]
const COURSE_ID = 1

describe('DifferentiatedModulesSection', () => {
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
    assignmentName: 'First Assignment',
    assignmentId: '1',
    type: 'assignment',
    pointsPossible: '10',
    overrides: assignmentcollection.models.map(model => model.toJSON().assignment_override),
    defaultSectionId: 0,
  }

  const SECTIONS_URL = `/api/v1/courses/${COURSE_ID}/sections`
  const STUDENTS_URL = `api/v1/courses/${COURSE_ID}/users?enrollment_type=student`

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
    fetchMock.get(STUDENTS_URL, []).get(SECTIONS_URL, SECTIONS_DATA)
  })

  afterEach(() => {
    fetchMock.resetHistory()
    fetchMock.restore()
  })

  it('renders', () => {
    const {getByText} = render(<DifferentiatedModulesSection {...props} />)
    expect(getByText('Manage Assign To')).toBeInTheDocument()
  })

  it('opens ItemAssignToTray', () => {
    const {getByText, getByTestId} = render(<DifferentiatedModulesSection {...props} />)
    getByTestId('manage-assign-to').click()
    expect(getByText('First Assignment')).toBeInTheDocument()
  })

  it('calls onSync when saving changes made in ItemAssignToTray', () => {
    const onSyncMock = jest.fn()
    const {getByRole, getByTestId} = render(
      <DifferentiatedModulesSection {...props} onSync={onSyncMock} />
    )

    getByTestId('manage-assign-to').click()
    getByRole('button', {name: 'Apply'}).click()
    expect(onSyncMock).toHaveBeenCalledWith(
      assignmentcollection.models.map(model =>
        expect.objectContaining({
          id: model.get('id'),
          assignment_id: model.get('assignment_id'),
          title: model.get('title'),
          due_at: model.get('due_at'),
          all_day: model.get('all_day'),
          all_day_date: model.get('all_day_date'),
          unlock_at: model.get('unlock_at'),
          lock_at: model.get('lock_at'),
          course_section_id: model.get('course_section_id'),
          due_at_overridden: model.get('due_at_overridden'),
          unlock_at_overridden: model.get('unlock_at_overridden'),
          lock_at_overridden: model.get('lock_at_overridden'),
        })
      ),
      props.importantDates
    )
  })

  describe('pending changes', () => {
    const addAssignee = async (getByTestId, findByTestId, findByText) => {
      getByTestId('manage-assign-to').click()
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())
    }

    it('highlights card if it has changes', async () => {
      const {getByTestId, findByTestId, findByText} = render(
        <DifferentiatedModulesSection {...props} />
      )
      await addAssignee(getByTestId, findByTestId, findByText)
      expect(getByTestId('highlighted_card')).toBeInTheDocument()
    })
    // skipping for now, since the pill is being validated in selenium specs
    it.skip('reverts highlighted style when changes are removed', async () => {
      const {getByTestId, findByTestId, findByText, getByText, queryByTestId} = render(
        <DifferentiatedModulesSection {...props} />
      )
      await addAssignee(getByTestId, findByTestId, findByText)
      expect(getByTestId('highlighted_card')).toBeInTheDocument()

      const selectedOption = getByText(SECTIONS_DATA[0].name)
      act(() => selectedOption.click())
      expect(queryByTestId('highlighted_card')).not.toBeInTheDocument()
    })
    // skipping for now, since the pill is being validated in selenium specs
    it.skip('shows pending changes pill', async () => {
      const {getByTestId, findByTestId, findByText, getByRole} = render(
        <DifferentiatedModulesSection {...props} />
      )
      await addAssignee(getByTestId, findByTestId, findByText)
      expect(getByTestId('highlighted_card')).toBeInTheDocument()
      getByRole('button', {name: 'Close'}).click()
      expect(getByTestId('pending_changes_pill')).toBeInTheDocument()
    })
  })

  describe('important dates', () => {
    beforeAll(() => {
      global.ENV = {
        K5_SUBJECT_COURSE: true,
      }
    })

    it('does not render the option for non-assignment items', () => {
      const {queryByTestId} = render(<DifferentiatedModulesSection {...props} type="quiz" />)

      expect(queryByTestId('important_dates')).not.toBeInTheDocument()
    })

    it('calls onSync with the importantDates flag when checking/unchecking the option', () => {
      const onSyncMock = jest.fn()
      const {getByTestId} = render(<DifferentiatedModulesSection {...props} onSync={onSyncMock} />)

      getByTestId('important_dates').click()
      expect(onSyncMock).toHaveBeenCalledWith(undefined, true)

      getByTestId('important_dates').click()
      expect(onSyncMock).toHaveBeenCalledWith(undefined, false)
    })

    it('disables the importantDates check when no due dates are set', () => {
      const override = assignmentcollection.models[0]
      override.set('due_at', '')
      const {getByTestId} = render(
        <DifferentiatedModulesSection {...props} overrides={[override]} />
      )

      expect(getByTestId('important_dates')).toBeDisabled()
    })
  })
})
