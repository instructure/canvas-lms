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
import {render} from 'react-testing-library'
import {closest, mockAssignment, mockUser, mockSubmission} from '../../test-utils'
import apiUserContent from 'compiled/str/apiUserContent'
import Students from '../Students'

import I18n from 'i18n!assignments_2'
import tz from 'timezone'

jest.mock('compiled/str/apiUserContent')
apiUserContent.convert = jest.fn(arg => `converted ${arg}`)

it('renders basic information', () => {
  const user = mockUser()
  const submission = mockSubmission({nodes: [user]})
  const assignment = mockAssignment({
    submissions: {
      nodes: [submission]
    }
  })
  const submittedAt = `${tz.format(submission.submittedAt, I18n.t('#date.formats.full'))}`

  const {getByText} = render(<Students assignment={assignment} />)
  expect(getByText('Name')).toBeInTheDocument()
  expect(getByText(user.shortName)).toBeInTheDocument()
  expect(getByText('Attempts')).toBeInTheDocument()
  expect(getByText('View Submission')).toBeInTheDocument()
  expect(getByText('Score')).toBeInTheDocument()
  expect(getByText('4/5')).toBeInTheDocument()
  expect(getByText('Submission Date')).toBeInTheDocument()
  expect(getByText(submittedAt)).toBeInTheDocument()
  expect(getByText('Status')).toBeInTheDocument()
  expect(getByText('More')).toBeInTheDocument()

  const viewSubmissionLink = closest(getByText('View Submission'), 'a')
  expect(viewSubmissionLink).toBeTruthy()
  expect(viewSubmissionLink.getAttribute('href')).toMatch(
    /\/courses\/course-lid\/assignments\/assignment-lid\/submissions\/user_1/
  )
})

it('renders submission status pill', () => {
  const user = mockUser()
  const submission = mockSubmission({
    submittedAt: null,
    submissionStatus: 'late',
    nodes: [user]
  })
  const assignment = mockAssignment({
    submissions: {
      nodes: [submission]
    }
  })
  const submittedAt = `${tz.format(submission.submittedAt, I18n.t('#date.formats.full'))}`

  const {queryByText, getByText} = render(<Students assignment={assignment} />)
  expect(queryByText('View Submission', {exact: false})).toBeNull()
  expect(queryByText(submittedAt)).toBeNull()
  expect(getByText('Late')).toBeInTheDocument()
})
