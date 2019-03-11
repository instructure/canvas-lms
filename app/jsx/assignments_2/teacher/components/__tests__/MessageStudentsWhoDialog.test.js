/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from 'react-testing-library'
import MessageStudentsWhoDialog from '../MessageStudentsWhoDialog'
import {mockAssignment} from '../../test-utils'
// import {sendMesssageStudentsWho} from '../../api'

// jest.mock('../../api')

function renderMessageStudentsWhoDialog(assignment = mockAssignment(), propsOverride = {}) {
  const props = {
    assignment,
    open: true,
    busy: false,
    onSend: () => {},
    onClose: () => {},
    ...propsOverride
  }
  return render(<MessageStudentsWhoDialog {...props} />)
}

describe('MessageStudentsWhoDialog', () => {
  describe('filters', () => {
    it('does not show the not unsubmitted filter when the assignment has no submissions', () => {})
    it('populates the students list when the not submitted filter is selected', () => {})
    it('populates the students list when the ungraded filter is selected', () => {})
    it('populates the students list when the scored less than filter is selected', () => {})
    it('populates the students list when the scored more than filter is selected', () => {})
    it('populates the students list when the points field is modified', () => {})
  })

  describe('points threshold', () => {
    it('does not show points with not submitted filter', () => {})
    it('does not show points with ungraded filter', () => {})

    it('shows points with scored greater than filter', () => {
      const {getByText, getByPlaceholderText, getByTestId} = renderMessageStudentsWhoDialog()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      expect(getByPlaceholderText('Points')).toBeInTheDocument()
    })

    it('shows points with less than filter', () => {})
    it('allows a blank value and treats it as 0', () => {})
    it('increments', () => {})
    it('decrements', () => {})
    it('increments with blank value', () => {})
    it('decrements with blank value', () => {})
    it('does not allow negative points', () => {})
  })

  describe('students list', () => {
    it('changes the student list when the "not submitted" filter is selected', () => {})
    it('changes the student list when the "ungraded" filter is selected', () => {})
    it('changes the student list when the "less than" filter is selected', () => {})
    it('changes the student list when the "greater than" filter is selected', () => {})
    it('changes the student list when the points field changes', () => {})
    it('can remove students', () => {})
    it('can add students', () => {})
    it('resets the student list when the filter changes, even when the students list has changed', () => {})
    it('resets the student list when the points field changes, even when the student list has changed ', () => {})
  })

  describe('subject autofill', () => {
    it('autofills the subject field when the filter changes', () => {})
    it('autofills the subject field when the points change', () => {})
  })

  describe('text fields', () => {
    it('allows typing in a subject', () => {})
    it('allows typing in a body', () => {})
  })

  describe('save button enabled', () => {
    it('is disabled when subject is blank', () => {})
    it('is disabled when the body is blank', () => {})
    it('is disabled when no students are selected', () => {})
    it('is enabled when there is a subject, body, and students to message', () => {})
  })

  describe('sending messages', () => {
    it('displays success and closes the dialog when the api call succeeds', () => {})
    it('displays an error and closes the dialog when the api call fails', () => {})
  })
})
