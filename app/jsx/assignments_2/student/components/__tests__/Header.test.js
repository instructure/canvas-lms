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
import {mockAssignmentAndSubmission, mockSubmission} from '../../mocks'
import React from 'react'
import {render} from '@testing-library/react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '../../graphqlData/Submission'

jest.mock('../AttemptSelect')

it('renders normally', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('assignment-student-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when less than threshold', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()
})

it('dispatches scroll event properly when greater than threshold', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 500
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-sticky')).toBeInTheDocument()
})

it('displays element filler when scroll offset is in correct place', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('assignment-student-pizza-header-normal')).toBeInTheDocument()

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('header-element-filler')).toBeInTheDocument()
  expect(getByTestId('assignment-student-header-sticky')).toBeInTheDocument()
})

it('will render the uncollapsed step container when scroll offset is less than scroll threshold', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: SubmissionMocks.submitted
  })
  const {getByTestId, queryByTestId} = render(<Header {...props} />)
  const scrollEvent = new Event('scroll')

  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('submitted-step-container')).toBeInTheDocument()
  expect(queryByTestId('collapsed-step-container')).not.toBeInTheDocument()
})

it('will render the collapsed step container when scroll offset is greater than scroll threshold', async () => {
  const props = await mockAssignmentAndSubmission()
  const {getByTestId} = render(<Header {...props} />)
  const scrollEvent = new Event('scroll')

  window.pageYOffset = 200
  window.dispatchEvent(scrollEvent)

  expect(getByTestId('collapsed-step-container')).toBeInTheDocument()
})

it('will not render LatePolicyStatusDisplay if the submission is not late', async () => {
  const props = await mockAssignmentAndSubmission()
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('late-policy-container')).not.toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the submission status is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      submissionStatus: 'late'
    }
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render LatePolicyStatusDisplay if the latePolicyStatus is late', async () => {
  const props = await mockAssignmentAndSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      latePolicyStatus: 'late'
    }
  })
  const {getByTestId} = render(<Header {...props} />)
  expect(getByTestId('late-policy-container')).toBeInTheDocument()
})

it('will render the latest grade instead of the displayed submissions grade', async () => {
  const latestSubmission = await mockSubmission({
    Submission: {
      ...SubmissionMocks.graded,
      grade: '147',
      enteredGrade: '147'
    }
  })

  const props = await mockAssignmentAndSubmission({
    Assignment: {pointsPossible: 150},
    Submission: {
      ...SubmissionMocks.graded,
      grade: '131',
      enteredGrade: '131'
    }
  })

  const {queryByText, queryAllByText} = render(
    <StudentViewContext.Provider value={{latestSubmission}}>
      <Header {...props} />
    </StudentViewContext.Provider>
  )

  expect(queryAllByText('147/150 Points')[0]).toBeInTheDocument()
  expect(queryByText('131/150 Points')).not.toBeInTheDocument()
})

it('will render the unavailable pizza tracker if there is a module prereq lock', async () => {
  const props = await mockAssignmentAndSubmission()
  props.assignment.env.modulePrereq = 'simulate not null'
  const {queryByTestId} = render(<Header {...props} />)
  expect(queryByTestId('unavailable-step-container')).toBeInTheDocument()
})
