/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import StudentContent from '../StudentContent'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {withSubmissionContext} from '../../test-utils/submission-context'

function setupEnv(overrides = {}) {
  global.ENV = {
    ASSET_PROCESSORS: [{id: 'processor1', tool_name: 'Processor 1'}],
    ASSET_REPORTS: [{asset: {_id: '1', attachment_id: '1'}, priority: 0}],
    ASSIGNMENT_NAME: 'Test Assignment',
    ...overrides,
  }
}

describe('StudentContent asset processor functionality', () => {
  it('renders AssetReportStatus and StudentAssetReportModal for single attachment when asset processor data is available', async () => {
    setupEnv()
    const user = userEvent.setup()
    const props = await mockAssignmentAndSubmission({
      Assignment: {_id: 'a1', name: 'Test Assignment'},
      Submission: {
        _id: 's1',
        attachments: [{_id: '1', displayName: 'file1', id: '1'}],
      },
    })

    render(
      <MockedProvider>
        {withSubmissionContext(<StudentContent {...props} />, {
          assignmentId: props.assignment._id,
          submissionId: props.submission._id,
        })}
      </MockedProvider>,
    )

    expect(screen.getByText('Document processors')).toBeInTheDocument()
    expect(screen.getByText('All good')).toBeInTheDocument()

    await user.click(screen.getByText('All good'))

    await screen.findByText('Document Processors for Test Assignment')
  })

  it('does not render AssetReportStatus if asset processor data is not available', async () => {
    setupEnv({ASSET_PROCESSORS: [], ASSET_REPORTS: []})
    const props = await mockAssignmentAndSubmission({
      Assignment: {_id: 'a1', name: 'Test Assignment'},
      Submission: {
        _id: 's1',
        attachments: [{_id: '1', displayName: 'file1', id: '1'}],
      },
    })

    render(
      <MockedProvider>
        {withSubmissionContext(<StudentContent {...props} />, {
          assignmentId: props.assignment._id,
          submissionId: props.submission._id,
        })}
      </MockedProvider>,
    )

    expect(screen.queryByText('Document processors')).not.toBeInTheDocument()
    expect(screen.queryByText('All good')).not.toBeInTheDocument()
  })

  it('does not render AssetReportStatus if there is not exactly one attachment', async () => {
    setupEnv()
    const props = await mockAssignmentAndSubmission({
      Assignment: {_id: 'a1', name: 'Test Assignment'},
      Submission: {
        _id: 's1',
        attachments: [
          {_id: '1', id: '1'},
          {_id: '2', id: '2'},
        ],
      },
    })

    render(
      <MockedProvider>
        {withSubmissionContext(<StudentContent {...props} />, {
          assignmentId: props.assignment._id,
          submissionId: props.submission._id,
        })}
      </MockedProvider>,
    )

    expect(screen.queryByText('Document processors')).not.toBeInTheDocument()
  })

  it('does not render StudentAssetReportModal without clicking on the status', async () => {
    setupEnv()
    const props = await mockAssignmentAndSubmission({
      Assignment: {_id: 'a1', name: 'Test Assignment'},
      Submission: {
        _id: 's1',
        attachments: [{_id: '1', displayName: 'file1', id: '1'}],
      },
    })

    render(
      <MockedProvider>
        {withSubmissionContext(<StudentContent {...props} />, {
          assignmentId: props.assignment._id,
          submissionId: props.submission._id,
        })}
      </MockedProvider>,
    )

    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })
})
