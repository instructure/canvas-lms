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
import StudentViewContext from '../Context'
import SubmissionManager from '../SubmissionManager'
import {SubmissionMocks} from '../../graphqlData/Submission'

describe('SubmissionManager', () => {
  it('renders the AttemptTab', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByTestId('attempt-tab')).toBeInTheDocument()
  })

  it('does not render a submit button when the draft criteria is not met', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('renders a submit button when the draft criteria is met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit')).toBeInTheDocument()
  })

  it('does not render the submit button if the draft criteria is not met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_upload',
          body: 'some text here'
        }
      }
    })
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('does not render the submit button if we are not on the latest submission', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })
    const {queryByText} = render(
      <StudentViewContext.Provider value={{nextButtonEnabled: true}}>
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      </StudentViewContext.Provider>
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('does not render the submit button if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true},
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('disables the submit button after it is pressed', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
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

  describe('with multiple submission types drafted', () => {
    it('renders a confirmation modal if the submit button is pressed', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_url']
        },
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_text_entry',
            body: 'some text here',
            meetsTextEntryCriteria: true,
            meetsUrlCriteria: true,
            url: 'http://www.google.com'
          }
        }
      })

      const {getByTestId, getByText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const submitButton = getByText('Submit')
      fireEvent.click(submitButton)

      expect(getByTestId('submission-confirmation-modal')).toBeInTheDocument()
      expect(getByTestId('cancel-submit')).toBeInTheDocument()
      expect(getByTestId('confirm-submit')).toBeInTheDocument()
    })
  })
})
