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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

vi.mock('../AttemptSelect')

vi.mock('../../apis/ContextModuleApi')

vi.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: vi.fn(),
  }
})

vi.mock('@canvas/assignments/react/AssignmentExternalTools', () => ({
  __esModule: true,
  default: {
    attach: vi.fn(),
  },
}))

describe('StudentContent Attempt Select', () => {
  beforeEach(() => {
    fakeENV.setup({current_user: {id: '1'}})
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('does not render the attempt select if allSubmissions is not provided', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if the assignment has non-digital submissions', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {nonDigitalSubmission: true},
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if peerReviewModeEnabled is set to true', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = true
    props.assignment.env.peerReviewAvailable = true
    props.allSubmissions = [props.submission]
    props.reviewerSubmission = {
      ...props.submission,
      assignedAssessments: [
        {
          assetId: '1',
          anonymousUser: null,
          anonymousId: 'xaU9cd',
          workflowState: 'assigned',
          assetSubmissionType: 'online_text_entry',
        },
      ],
    }
    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('renders the attempt select if peerReviewModeEnabled is set to false', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = false
    props.allSubmissions = [props.submission]
    const {queryByTestId} = render(
      <MockedQueryProvider>
        <StudentContent {...props} />
      </MockedQueryProvider>,
    )
    expect(queryByTestId('attemptSelect')).toBeInTheDocument()
  })
})
