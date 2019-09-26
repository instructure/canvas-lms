/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {AlertManagerContext} from '../../../../shared/components/AlertManager'
import {CREATE_SUBMISSION} from '../../graphqlData/Mutations'
import {fireEvent, render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import SubmissionManager from '../SubmissionManager'
import {SubmissionMocks} from '../../graphqlData/Submission'

describe('SubmissionManager', () => {
  it('renders the AttemptTab', async () => {
    const props = await mockAssignmentAndSubmission({})
    const {getByTestId} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByTestId('attempt-tab')).toBeInTheDocument()
  })

  it('does not render a submit button when the draft criteria is not met', async () => {
    const props = await mockAssignmentAndSubmission({})
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('renders a submit button when the draft criteria is met', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: () => SubmissionMocks.onlineUploadReadyToSubmit
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit')).toBeInTheDocument()
  })

  it('disables the submit button after it is pressed', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: () => SubmissionMocks.onlineUploadReadyToSubmit
    })

    const variables = {
      assignmentLid: '1',
      submissionID: '1',
      type: 'online_upload',
      fileIds: ['1']
    }
    const result = await mockQuery(CREATE_SUBMISSION, {}, variables)
    const mocks = [
      {
        request: {query: CREATE_SUBMISSION, variables},
        result
      }
    ]

    const {getByText} = render(
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <MockedProvider mocks={mocks}>
          <SubmissionManager {...props} />
        </MockedProvider>
      </AlertManagerContext.Provider>
    )

    const submitButton = getByText('Submit')
    fireEvent.click(submitButton)
    expect(getByText('Submit').closest('button')).toHaveAttribute('disabled')
  })
})
