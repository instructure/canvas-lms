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
  it('renders the content tabs', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getAllByTestId} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    expect(getAllByTestId('assignment-2-student-content-tabs')).toHaveLength(1)
  })

  it('renders the tabs in the correct order when the assignment has a rubric', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {rubric: {}}
    })

    const {getAllByRole} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')

    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('Attempt 1')
    expect(tabs[1]).toHaveTextContent('Rubric')
  })

  it('does not render the Rubric tab when the assignment has no rubric', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {rubric: null}
    })

    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')

    expect(tabs).toHaveLength(1)
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
  })

  it('titles the attempt tab as Attempt 1 on a brand new submission', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {attempt: 0}
    })
    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
  })

  it('titles the attempt tab with the correct attempt number on a submission with multiple attempts', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {attempt: 50}
    })
    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')
    expect(tabs[0]).toContainElement(getByText('Attempt 50'))
  })

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
