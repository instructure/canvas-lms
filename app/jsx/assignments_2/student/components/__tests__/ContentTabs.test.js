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
import {mockAssignment, mockSubmission} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {render} from 'react-testing-library'

describe('ContentTabs', () => {
  it('renders the content tabs', () => {
    const {getAllByTestId} = render(
      <MockedProvider>
        <ContentTabs assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    expect(getAllByTestId('assignment-2-student-content-tabs')).toHaveLength(1)
  })

  it('renders the tabs in the correct order', () => {
    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs assignment={mockAssignment()} submission={mockSubmission()} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')

    expect(tabs).toHaveLength(3)
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
    expect(tabs[1]).toContainElement(getByText('Comments'))
    expect(tabs[2]).toContainElement(getByText('Rubric'))
  })

  it('titles the attempt tab as Attempt 1 on a brand new submission', () => {
    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs assignment={mockAssignment()} submission={mockSubmission({attempt: 0})} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')
    expect(tabs[0]).toContainElement(getByText('Attempt 1'))
  })

  it('titles the attempt tab with the correct attempt number on a submission with multiple attempts', () => {
    const {getAllByRole, getByText} = render(
      <MockedProvider>
        <ContentTabs assignment={mockAssignment()} submission={mockSubmission({attempt: 50})} />
      </MockedProvider>
    )
    const tabs = getAllByRole('tab')
    expect(tabs[0]).toContainElement(getByText('Attempt 50'))
  })

  it('displays the submitted time and grade of the current submission if it has been submitted', () => {
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <ContentTabs
          assignment={mockAssignment()}
          submission={mockSubmission({state: 'submitted'})}
        />
      </MockedProvider>
    )

    expect(getByText('Submitted')).toBeInTheDocument()
    expect(getByTestId('friendly-date-time')).toBeInTheDocument()
    expect(getByTestId('grade-display')).toBeInTheDocument()
  })

  it('displays Not submitted if the submission has been graded but not submitted', () => {
    const {getByText, queryByTestId} = render(
      <MockedProvider>
        <ContentTabs
          assignment={mockAssignment()}
          submission={mockSubmission({state: 'graded', submittedAt: null})}
        />
      </MockedProvider>
    )

    expect(queryByTestId('friendly-date-time')).not.toBeInTheDocument()
    expect(getByText('Not submitted')).toBeInTheDocument()
  })

  it('displays the submitted time and grade of the current submission if it has been graded', () => {
    const {getByTestId, getByText} = render(
      <MockedProvider>
        <ContentTabs assignment={mockAssignment()} submission={mockSubmission({state: 'graded'})} />
      </MockedProvider>
    )

    expect(getByText('Submitted')).toBeInTheDocument()
    expect(getByTestId('friendly-date-time')).toBeInTheDocument()
    expect(getByTestId('grade-display')).toBeInTheDocument()
  })

  it('does not display the submitted time or grade of the current submission if it is unsubmitted', () => {
    const {queryByTestId, queryByText} = render(
      <MockedProvider>
        <ContentTabs
          assignment={mockAssignment()}
          submission={mockSubmission({state: 'unsubmitted'})}
        />
      </MockedProvider>
    )

    expect(queryByText('Submitted')).toBeNull()
    expect(queryByTestId('friendly-date-time')).toBeNull()
    expect(queryByTestId('grade-display')).toBeNull()
  })
})
