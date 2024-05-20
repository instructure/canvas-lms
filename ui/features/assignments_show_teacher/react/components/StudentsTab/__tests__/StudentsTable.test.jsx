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

import React from 'react'
import {render} from '@testing-library/react'
import {closest, mockAssignment, mockUser, mockSubmission} from '../../../test-utils'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import StudentsTable from '../StudentsTable'

import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'

const I18n = useI18nScope('assignments_2')

jest.mock('@canvas/util/jquery/apiUserContent')
apiUserContent.convert = jest.fn(arg => `converted ${arg}`)

function displayedTime(datetimeStr) {
  return `${tz.format(datetimeStr, I18n.t('#date.formats.full'))}`
}

it('renders basic information', () => {
  const user = mockUser()
  const submission = mockSubmission({nodes: [user]})
  const assignment = mockAssignment()

  const {getByText, getAllByText} = render(
    <StudentsTable assignment={assignment} submissions={[submission]} />
  )
  expect(getByText('Name')).toBeInTheDocument()
  expect(getByText(user.shortName)).toBeInTheDocument()
  expect(getByText('Attempts')).toBeInTheDocument()
  expect(getByText('Attempt 1')).toBeInTheDocument()
  expect(getByText('Score')).toBeInTheDocument()
  expect(getByText('4/5')).toBeInTheDocument()
  expect(getByText('Submission Date')).toBeInTheDocument()
  expect(getAllByText(displayedTime(submission.submittedAt))[0]).toBeInTheDocument()
  expect(getByText('Status')).toBeInTheDocument()
  expect(getByText('More')).toBeInTheDocument()

  const viewSubmissionLink = closest(getByText('Attempt 1'), 'a')
  expect(viewSubmissionLink).toBeTruthy()
  expect(viewSubmissionLink.getAttribute('href')).toMatch(
    /\/courses\/course-lid\/gradebook\/speed_grader\?assignment_id=assignment-lid&student_id=user_1&attempt=1/
  )
})

it('displays no attempts, scores, or submission dates with zero attempts', () => {
  const user = mockUser()
  const submission = mockSubmission({nodes: [user], submissionHistories: {nodes: []}})
  const assignment = mockAssignment()

  const {getByText, queryByText} = render(
    <StudentsTable assignment={assignment} submissions={[submission]} />
  )
  expect(getByText('Name')).toBeInTheDocument()
  expect(getByText(user.shortName)).toBeInTheDocument()
  expect(getByText('Attempts')).toBeInTheDocument()
  expect(queryByText(/Attempt 1/i)).toBeNull()
  expect(getByText('Score')).toBeInTheDocument()
  expect(queryByText('-/5')).toBeNull()
  expect(getByText('Submission Date')).toBeInTheDocument()
  expect(getByText('Status')).toBeInTheDocument()
  expect(getByText('More')).toBeInTheDocument()
})

it('displays multiple attempts', () => {
  const user = mockUser()
  const attempts = [
    {attempt: 1, score: 2, submittedAt: '2019-01-13T08:21:42Z'},
    {attempt: 2, score: 3, submittedAt: '2019-01-14T09:21:42Z'},
    {attempt: 3, score: 4, submittedAt: '2019-01-15T12:21:42Z'},
  ]
  const submission = mockSubmission({nodes: [user], submissionHistories: {nodes: attempts}})
  const assignment = mockAssignment()

  const {getByText, getAllByText} = render(
    <StudentsTable assignment={assignment} submissions={[submission]} />
  )
  expect(getAllByText('Attempt 1')[0]).toBeInTheDocument()
  expect(getAllByText('Attempt 2')[0]).toBeInTheDocument()
  expect(getByText('Attempt 3')).toBeInTheDocument()
  expect(getByText('2/5')).toBeInTheDocument()
  expect(getByText('3/5')).toBeInTheDocument()
  expect(getByText('4/5')).toBeInTheDocument()
  expect(getAllByText(displayedTime(attempts[0].submittedAt))[0]).toBeInTheDocument()
  expect(getAllByText(displayedTime(attempts[1].submittedAt))[0]).toBeInTheDocument()
  expect(getAllByText(displayedTime(attempts[2].submittedAt))[0]).toBeInTheDocument()

  const viewSubmissionLink = closest(getByText('Attempt 1'), 'a')
  expect(viewSubmissionLink.getAttribute('href')).toMatch(
    /\/courses\/course-lid\/gradebook\/speed_grader\?assignment_id=assignment-lid&student_id=user_1&attempt=1/
  )
})

it('indicates when a submission draft is present', () => {
  const user = mockUser()
  const submission = mockSubmission({
    nodes: [user],
    submissionHistories: {nodes: []},
    submissionDraft: {submissionAttempt: '0'},
  })
  const assignment = mockAssignment()

  const {getByText} = render(<StudentsTable assignment={assignment} submissions={[submission]} />)
  expect(getByText('In Progress')).toBeInTheDocument()
})

it('renders submission status pill', () => {
  const submission = mockSubmission({
    submittedAt: null,
    submissionStatus: 'late',
  })
  const assignment = mockAssignment()
  const submittedAt = `${tz.format(submission.submittedAt, I18n.t('#date.formats.full'))}`

  const {queryByText, getByText} = render(
    <StudentsTable assignment={assignment} submissions={[submission]} />
  )
  expect(queryByText('View Submission', {exact: false})).toBeNull()
  expect(queryByText(submittedAt)).toBeNull()
  expect(getByText('Late')).toBeInTheDocument()
})

it('renders excused status pill', () => {
  const submission = mockSubmission({
    submittedAt: null,
    submissionStatus: 'late',
    excused: true,
  })
  const assignment = mockAssignment()
  const submittedAt = `${tz.format(submission.submittedAt, I18n.t('#date.formats.full'))}`

  const {queryByText, getByText} = render(
    <StudentsTable assignment={assignment} submissions={[submission]} />
  )
  expect(queryByText('View Submission', {exact: false})).toBeNull()
  expect(queryByText(submittedAt)).toBeNull()
  expect(getByText('Excused')).toBeInTheDocument()
  expect(queryByText('Late')).toBeNull()
})

it('renders the specified sort direction', () => {
  const {getByText} = render(
    <StudentsTable
      assignment={mockAssignment()}
      submissions={[mockSubmission()]}
      sortableColumns={['username']}
      sortId="username"
      sortDirection="descending"
    />
  )
  const nameButton = closest(getByText('Name'), 'button')
  expect(nameButton.querySelector('[name="IconMiniArrowDown"]')).not.toBe(null)
})
