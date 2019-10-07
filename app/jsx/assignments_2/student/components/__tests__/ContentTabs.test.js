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
import {mockAssignmentAndSubmission} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {SubmissionMocks} from '../../graphqlData/Submission'

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

    const {getAllByRole, getByText, getAllByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')

    expect(tabs).toHaveLength(3)
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
    expect(tabs[1]).toContainElement(getAllByText('Comments')[0])
    expect(tabs[2]).toContainElement(getAllByText('Rubric')[0])
  })

  it('does not render the Rubric tab when the assignment has no rubric', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {rubric: null}
    })

    const {getAllByRole, getByText, getAllByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')

    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
    expect(tabs[1]).toContainElement(getAllByText('Comments')[0])
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

    expect(getByText('Submitted')).toBeInTheDocument()
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

    expect(getByText('Submitted')).toBeInTheDocument()
    expect(getByTestId('friendly-date-time')).toBeInTheDocument()
    expect(getByTestId('grade-display')).toBeInTheDocument()
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

    expect(queryByText('Submitted')).toBeInTheDocument()
    expect(queryByTestId('friendly-date-time')).toBeInTheDocument()
    expect(queryByTestId('grade-display')).toBeInTheDocument()
    expect(queryByText('–/10 Points')).toBeInTheDocument()
  })

  it('does not display the submitted time or grade of the current submission if it is unsubmitted', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByTestId, queryByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submitted')).toBeNull()
    expect(queryByTestId('friendly-date-time')).toBeNull()
    expect(queryByTestId('grade-display')).toBeNull()
  })

  it('displays the correct message if the submission grade has not been posted', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {posted: false}
    })

    const {getAllByText, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    fireEvent.click(getAllByText('Comments')[0])
    expect(
      getByText(
        'You may not see all comments right now because the assignment is currently being graded.'
      )
    ).toBeInTheDocument()
  })

  it('does not let you create comments if a dummy submission is being displayed', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {attempt: 2, state: 'unsubmitted'}
    })

    const {getAllByText, queryByTestId, getByText} = render(
      <MockedProvider>
        <ContentTabs {...props} />
      </MockedProvider>
    )
    fireEvent.click(getAllByText('Comments')[0])

    expect(queryByTestId('assignments_2_comment_attachment')).not.toBeInTheDocument()
    expect(
      getByText('You cannot leave leave comments until you submit the assignment')
    ).toBeInTheDocument()
  })
})
