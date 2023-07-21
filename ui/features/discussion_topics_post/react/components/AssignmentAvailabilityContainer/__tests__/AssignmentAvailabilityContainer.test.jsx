/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AssignmentAvailabilityContainer} from '../AssignmentAvailabilityContainer'
import {Assignment} from '../../../../graphql/Assignment'

import {responsiveQuerySizes} from '../../../utils/index'

import React from 'react'
import {act, fireEvent, render} from '@testing-library/react'

jest.mock('../../../utils')

const mockOverrides = [
  {
    id: 'QXNzaWdebTVubC0x',
    _id: '1',
    dueAt: '2021-03-30T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-24T00:00:00-06:00',
    title: 'assignment override 1',
  },
  {
    id: 'ZXMzaWdebTubeC0x',
    _id: '2',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 2',
  },
  {
    id: 'BXMzaWdebTVubC0x',
    _id: '3',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-09-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 3',
  },
]

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = (assignmentData = {}) => {
  return render(
    <AssignmentAvailabilityContainer
      assignment={Assignment.mock({...assignmentData})}
      isAdmin={true}
    />
  )
}

describe('AssignmentAvailabilityContainer', () => {
  describe('desktop', () => {
    it('displays due date when there are no overrides', () => {
      const {queryByText} = setup({
        assignmentOverrides: {nodes: []},
      })
      expect(queryByText('Everyone')).toBeTruthy()
      expect(queryByText('Due Mar 31, 2021 5:59am')).toBeTruthy()
      expect(queryByText('Available from Mar 24, 2021 until Apr 4, 2021')).toBeTruthy()
    })

    it('displays "Show due dates" button when there are overrides', () => {
      const {getByText} = setup({
        assignmentOverrides: {nodes: mockOverrides},
      })
      expect(getByText('Show Due Dates (4)')).toBeTruthy()
    })

    it('displays tray and correctly formatted dates', async () => {
      const {queryByText, findByText, findAllByTestId} = setup({
        assignmentOverrides: {nodes: mockOverrides},
      })
      expect(queryByText('Show Due Dates (4)')).toBeTruthy()
      fireEvent.click(queryByText('Show Due Dates (4)'))
      expect(await findAllByTestId('assignment-override-row')).toBeTruthy()
      expect(await findByText('Sep 4, 2021 5:59am')).toBeTruthy()
    })

    it('correct text is shown when a date is not set', async () => {
      mockOverrides[2].dueAt = null
      mockOverrides[2].unlockAt = null
      mockOverrides[2].lockAt = null
      const {queryByText, findByText} = setup({
        assignmentOverrides: {nodes: mockOverrides},
      })
      expect(queryByText('Show Due Dates (4)')).toBeTruthy()
      fireEvent.click(queryByText('Show Due Dates (4)'))
      expect(await findByText('No Due Date')).toBeTruthy()
      expect(await findByText('No Start Date')).toBeTruthy()
      expect(await findByText('No End Date')).toBeTruthy()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '767px'},
      }))
    })

    it('displays "Show due dates" button when there are overrides', () => {
      const {queryByText} = setup({
        assignmentOverrides: {nodes: mockOverrides},
      })
      expect(queryByText('Due Dates (4)')).toBeTruthy()
    })

    it('displays due date when there are no overrides', () => {
      const {getByText} = setup({
        assignmentOverrides: {nodes: []},
      })
      expect(getByText('Due Mar 31, 2021')).toBeTruthy()
    })

    it('displays no due date when there are no overrides and no due date', () => {
      const {queryByText} = setup({
        assignmentOverrides: {nodes: []},
        dueAt: '',
      })
      expect(queryByText('No Due Date')).toBeTruthy()
    })

    it('opens due date tray for single due date', () => {
      const {queryByText, getByText, getByTestId} = setup({
        assignmentOverrides: {nodes: []},
      })

      expect(queryByText('Due Mar 31, 2021')).toBeInTheDocument()
      const dueDateTrayButton = queryByText('Due Mar 31, 2021')
      fireEvent.click(dueDateTrayButton)
      expect(getByText('Due Mar 31, 2021')).toBeTruthy()
      expect(getByTestId('assignment-override-row')).toBeTruthy()
    })

    it("due date tray doesn't show assignment context when not admin", () => {
      const {queryByText, getByText, queryByTestId} = setup({
        assignmentOverrides: {nodes: []},
        isAdmin: false,
      })

      expect(queryByText('Due Mar 31, 2021')).toBeInTheDocument()
      const dueDateTrayButton = queryByText('Due Mar 31, 2021')
      fireEvent.click(dueDateTrayButton)
      expect(getByText('Due Mar 31, 2021')).toBeTruthy()
      expect(queryByTestId('due_date_tray_header_for')).toBeNull()
    })
  })
  describe('in a paced course', () => {
    it('always uses the multiple due dates UI even with 1 due dat', async () => {
      const {findByTestId, getByRole} = render(
        <AssignmentAvailabilityContainer
          assignment={Assignment.mock({assignmentOverrides: {nodes: []}})}
          isAdmin={true}
          inPacedCourse={true}
          courseId="17"
        />
      )
      act(() => {
        getByRole('button', {name: 'Show Due Dates (1)'}).click()
      })

      expect(await findByTestId('CoursePacingNotice')).toBeInTheDocument()
      const pacingLink = getByRole('link', {name: 'Course Pacing'})
      expect(pacingLink).toBeInTheDocument()
      expect(pacingLink.href).toMatch(/\/courses\/17\/course_pacing/)
    })

    it('shows the course pacing notice', async () => {
      const {findByTestId, getByRole} = render(
        <AssignmentAvailabilityContainer
          assignment={Assignment.mock({assignmentOverrides: {nodes: mockOverrides}})}
          isAdmin={true}
          inPacedCourse={true}
          courseId="17"
        />
      )
      act(() => {
        getByRole('button', {name: 'Show Due Dates (4)'}).click()
      })

      expect(await findByTestId('CoursePacingNotice')).toBeInTheDocument()
      const pacingLink = getByRole('link', {name: 'Course Pacing'})
      expect(pacingLink).toBeInTheDocument()
      expect(pacingLink.href).toMatch(/\/courses\/17\/course_pacing/)
    })
  })
})
