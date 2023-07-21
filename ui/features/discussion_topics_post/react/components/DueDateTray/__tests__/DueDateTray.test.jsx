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

import {AdhocStudents, Student} from '../../../../graphql/AdhocStudents'
import {AssignmentOverride} from '../../../../graphql/AssignmentOverride'
import {DueDateTray} from '../DueDateTray'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

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

const overrides = [
  AssignmentOverride.mock({title: 'assignment override 1', adhocStudents: null}),
  AssignmentOverride.mock({
    id: 'QXNzaWdubWVudE92ZXJyaWRlLTI=',
    _id: '2',
    title: 'assignment override 2',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-04-07T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    adhocStudents: null,
  }),
  AssignmentOverride.mock({
    id: 'QXNzaWdubWVudE92ZXJyaWRlLTM=',
    _id: '3',
    title: 'assignment override 3',
    dueAt: '2021-05-27T23:59:59-06:00',
    lockAt: '2021-09-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    adhocStudents: null,
  }),
]

const setup = props => {
  return render(<DueDateTray assignmentOverrides={overrides} {...props} />)
}

describe('DueDateTray', () => {
  describe('desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'},
      }))
    })

    it('displays tray and correctly formatted dates', () => {
      const {getByText} = setup()
      expect(getByText('Due Dates')).toBeInTheDocument()
      expect(getByText('Mar 31, 2021 5:59am')).toBeInTheDocument()
      expect(getByText('assignment override 1')).toBeInTheDocument()
      expect(getByText('Mar 24, 2021 6am')).toBeInTheDocument()
      expect(getByText('Apr 4, 2021 5:59am')).toBeInTheDocument()
    })

    it('correct text is shown when a date is not set', () => {
      const {getByText} = setup({
        assignmentOverrides: [
          AssignmentOverride.mock({
            dueAt: null,
            unlockAt: null,
            lockAt: null,
          }),
        ],
      })
      expect(getByText('No Due Date')).toBeInTheDocument()
      expect(getByText('No Start Date')).toBeInTheDocument()
      expect(getByText('No End Date')).toBeInTheDocument()
    })

    it('renders the students names if present', () => {
      const {getByText} = setup({assignmentOverrides: [AssignmentOverride.mock()]})
      expect(
        getByText(
          AdhocStudents.mock()
            .students.map(student => student.shortName)
            .join(', ')
        )
      ).toBeInTheDocument()
    })

    it('truncates the student names if there are more than 10', () => {
      const students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(val =>
        Student.mock({shortName: `Student${val}`})
      )
      const {getByText} = setup({
        assignmentOverrides: [
          AssignmentOverride.mock({
            adhocStudents: AdhocStudents.mock({
              students,
            }),
          }),
        ],
      })
      expect(
        getByText(
          students
            .slice(0, 5)
            .map(student => student.shortName)
            .join(', ')
        )
      ).toBeInTheDocument()
      expect(getByText('...')).toBeInTheDocument()
      expect(getByText('6 more')).toBeInTheDocument()
    })

    it('allows expanding the student names if there are more than 10', () => {
      const students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(val =>
        Student.mock({shortName: `Student${val}`})
      )
      const {getByText} = setup({
        assignmentOverrides: [
          AssignmentOverride.mock({
            adhocStudents: AdhocStudents.mock({
              students,
            }),
          }),
        ],
      })
      fireEvent.click(getByText('6 more'))
      expect(getByText(students.map(student => student.shortName).join(', '))).toBeInTheDocument()
      expect(getByText('6 less')).toBeInTheDocument()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '1000px'},
      }))
    })

    it('displays tray and correctly formatted dates', () => {
      const {getByText} = setup()
      expect(getByText('Mar 31, 2021 5:59am')).toBeInTheDocument()
      expect(getByText('assignment override 1')).toBeInTheDocument()
      expect(getByText('Mar 24, 2021 6am')).toBeInTheDocument()
      expect(getByText('Apr 4, 2021 5:59am')).toBeInTheDocument()
    })

    it('correct text is shown when a date is not set', () => {
      const {getByText} = setup({
        assignmentOverrides: [
          AssignmentOverride.mock({
            dueAt: null,
            unlockAt: null,
            lockAt: null,
          }),
        ],
      })
      expect(getByText('No Due Date')).toBeInTheDocument()
      expect(getByText('No Start Date')).toBeInTheDocument()
      expect(getByText('No End Date')).toBeInTheDocument()
    })
  })
})
