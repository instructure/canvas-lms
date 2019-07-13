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
import {legacyMockSubmission, mockAssignment} from '../../test-utils'
import React from 'react'
import StudentViewContext from '../Context'
import {render} from 'react-testing-library'

// TODO: is scroll threshold is always 150 in every case, why are we passing
//       that down as a prop instead of just having it be a constant in the
//       component or a default prop value?

it('renders normally', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )

  expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when less than threshold', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when greater than threshold', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 500
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-sticky')).toBeInTheDocument()
})

it('displays element filler when scroll offset is in correct place', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('header-element-filler')).toBeInTheDocument()
  expect(getByTestId('assignment-student-header-sticky')).toBeInTheDocument()
})

it('will render the uncollapsed step container when scroll offset is less than scroll threshold', () => {
  const assignment = mockAssignment()
  const submission = legacyMockSubmission()
  assignment.lockInfo.isLocked = false
  submission.state = 'submitted'

  const {getByTestId, queryByTestId} = render(
    <Header scrollThreshold={150} assignment={assignment} submission={submission} />
  )
  const scrollEvent = new Event('scroll')

  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  expect(queryByTestId('collapsed-step-container')).not.toBeInTheDocument()
})

it('will render the collapsed step container when scroll offset is greater than scroll threshold', () => {
  const {getByTestId} = render(
    <Header
      scrollThreshold={150}
      assignment={mockAssignment()}
      submission={legacyMockSubmission()}
    />
  )
  const scrollEvent = new Event('scroll')

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('collapsed-step-container')).toBeInTheDocument()
})

it('will not render LatePolicyStatusDisplay if the submission is not late', () => {
  const submission = legacyMockSubmission()
  submission.latePolicyStatus = null
  submission.submissionStatus = null
  const {queryByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(queryByTestId('late-policy-container')).not.toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the submission status is late', () => {
  const submission = legacyMockSubmission()
  submission.latePolicyStatus = null
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the latePolicyStatus is late', () => {
  const submission = legacyMockSubmission()
  submission.submissionStatus = null
  const {getByTestId} = render(
    <Header scrollThreshold={150} assignment={mockAssignment()} submission={submission} />
  )

  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render the latest grade instead of the displayed submissions grade', () => {
  const assignment = mockAssignment()
  const displayedSubmission = legacyMockSubmission()
  const latestSubmission = legacyMockSubmission()
  displayedSubmission.grade = '131'
  latestSubmission.grade = '147'
  assignment.gradingType = 'points'
  assignment.pointsPossible = 150

  const {queryByText} = render(
    <StudentViewContext.Provider value={{latestSubmission}}>
      <Header scrollThreshold={150} assignment={assignment} submission={displayedSubmission} />
    </StudentViewContext.Provider>
  )

  expect(queryByText('147/150 Points')).toBeInTheDocument()
  expect(queryByText('131/150 Points')).not.toBeInTheDocument()
})
