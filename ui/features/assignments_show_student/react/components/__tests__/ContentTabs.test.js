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

import ContentTabs from '../ContentTabs'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render} from '@testing-library/react'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

describe('ContentTabs', () => {
  it('displays the submitted time and grade of the current submission if it has been submitted', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.submitted
    })

    const {getByTestId, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )

    expect(getByText('Submitted:')).toBeInTheDocument()
    expect(getByTestId('friendly-date-time')).toBeInTheDocument()
    expect(getByTestId('grade-display')).toBeInTheDocument()
  })

  it('displays Not submitted if the submission has been graded but not submitted', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {state: 'graded'}
    })
    const {getByText, queryByTestId} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )

    expect(queryByTestId('friendly-date-time')).not.toBeInTheDocument()
    expect(getByText('Not submitted')).toBeInTheDocument()
  })

  it('displays the submitted time and grade of the current submission if it has been graded', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.graded
    })

    const {getByTestId, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )

    expect(getByText('Submitted:')).toBeInTheDocument()
    expect(getByTestId('friendly-date-time')).toBeInTheDocument()
    expect(getByTestId('grade-display')).toBeInTheDocument()
  })

  it('displays the grade of the current submission when it is excused', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.excused
    })

    const {getByTestId} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    expect(getByTestId('grade-display').textContent).toEqual('–/10 Points')
  })

  it('does not display the grade of the current submission if it is submitted but not graded', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.submitted
    })
    const {queryByTestId, queryByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submitted:')).toBeInTheDocument()
    expect(queryByTestId('friendly-date-time')).toBeInTheDocument()
    expect(queryByTestId('grade-display')).toBeInTheDocument()
    expect(queryByText('–/10 Points')).toBeInTheDocument()
  })
})
