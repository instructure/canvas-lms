/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Header from '../Header'
import {mockAssignment} from '../../test-utils'
import React from 'react'
import {render} from 'react-testing-library'

it('renders normally', () => {
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={mockAssignment()} />)

  expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when less than threshold', () => {
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={mockAssignment()} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when greater than threshold', () => {
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={mockAssignment()} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 500
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-sticky')).toBeInTheDocument()
})

it('displays element filler when scroll offset is in correct place', () => {
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={mockAssignment()} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('header-element-filler')).toBeInTheDocument()
  expect(getByTestId('assignment-student-header-sticky')).toBeInTheDocument()
})

it('will not render LatePolicyStatusDisplay if the submission is not late', () => {
  const assignment = mockAssignment()
  assignment.submissionsConnection.nodes[0].latePolicyStatus = null
  assignment.submissionsConnection.nodes[0].submissionStatus = null
  const {queryByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(queryByTestId('late-policy-container')).not.toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the submission status is late', () => {
  const assignment = mockAssignment()
  assignment.submissionsConnection.nodes[0].latePolicyStatus = null
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the latePolicyStatus is late status is late', () => {
  const assignment = mockAssignment()
  assignment.submissionsConnection.nodes[0].submissionStatus = null
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render the unavailable state tracker if an assignment is not available', () => {
  const assignment = mockAssignment()
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('unavailable-step-container')).toBeInTheDocument()
})

it('will render the available state tracker if an assignment is available but not submitted', () => {
  const assignment = mockAssignment()
  assignment.lockInfo.isLocked = false
  assignment.submissionsConnection.nodes[0].state = 'unsubmitted'
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('available-step-container')).toBeInTheDocument()
})

it('will render the submitted state tracker if an assignment is submitted but not graded', () => {
  const assignment = mockAssignment()
  assignment.lockInfo.isLocked = false
  assignment.submissionsConnection.nodes[0].state = 'submitted'
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('submitted-step-container')).toBeInTheDocument()
})

it('will render the graded state tracker if an assignment is graded', () => {
  const assignment = mockAssignment()
  assignment.lockInfo.isLocked = false
  assignment.submissionsConnection.nodes[0].state = 'graded'
  const {getByTestId} = render(<Header scrollThreshold={150} assignment={assignment} />)

  expect(getByTestId('graded-step-container')).toBeInTheDocument()
})
