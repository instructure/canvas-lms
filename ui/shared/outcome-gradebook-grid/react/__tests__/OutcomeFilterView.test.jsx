/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import OutcomeFilterView from '../OutcomeFilterView'

const defaultProps = () => ({
  showInactiveEnrollments: false,
  showConcludedEnrollments: false,
  showUnassessedStudents: false,
  toggleInactiveEnrollments: () => {},
  toggleConcludedEnrollments: () => {},
  toggleUnassessedStudents: () => {},
})

it('calls toggleInactiveEnrollments to enable displaying inactive enrollments', () => {
  const toggleInactiveEnrollments = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView {...defaultProps()} toggleInactiveEnrollments={toggleInactiveEnrollments} />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Inactive enrollments'))
  expect(toggleInactiveEnrollments).toHaveBeenCalledWith(true)
})

it('calls toggleInactiveEnrollments to disable displaying inactive enrollments', () => {
  const toggleInactiveEnrollments = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView
      {...defaultProps()}
      toggleInactiveEnrollments={toggleInactiveEnrollments}
      showInactiveEnrollments={true}
    />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Inactive enrollments'))
  expect(toggleInactiveEnrollments).toHaveBeenCalledWith(false)
})

it('calls toggleConcludedEnrollments to enable displaying Concluded enrollments', () => {
  const toggleConcludedEnrollments = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView
      {...defaultProps()}
      toggleConcludedEnrollments={toggleConcludedEnrollments}
    />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Concluded enrollments'))
  expect(toggleConcludedEnrollments).toHaveBeenCalledWith(true)
})

it('calls toggleConcludedEnrollments to disable displaying Concluded enrollments', () => {
  const toggleConcludedEnrollments = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView
      {...defaultProps()}
      toggleConcludedEnrollments={toggleConcludedEnrollments}
      showConcludedEnrollments={true}
    />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Concluded enrollments'))
  expect(toggleConcludedEnrollments).toHaveBeenCalledWith(false)
})

it('calls toggleUnassessedStudents to enable displaying Unassessed students', () => {
  const toggleUnassessedStudents = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView {...defaultProps()} toggleUnassessedStudents={toggleUnassessedStudents} />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Unassessed students'))
  expect(toggleUnassessedStudents).toHaveBeenCalledWith(true)
})

it('calls toggleUnassessedStudents to disable displaying Unassessed students', () => {
  const toggleUnassessedStudents = jest.fn()
  const {getByText, getByRole} = render(
    <OutcomeFilterView
      {...defaultProps()}
      toggleUnassessedStudents={toggleUnassessedStudents}
      showUnassessedStudents={true}
    />
  )
  fireEvent.click(getByRole('button'))
  fireEvent.click(getByText('Unassessed students'))
  expect(toggleUnassessedStudents).toHaveBeenCalledWith(false)
})
