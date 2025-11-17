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
import React from 'react'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {LtiAssetReportsForStudentSubmission} from '../LtiAssetReportsForStudentSubmission'
import {defaultGetLtiAssetProcessorsAndReportsForStudentResult} from '../../queries/__fixtures__/LtiAssetProcessorsAndReportsForStudent'

describe('LtiAssetReportsForStudentSubmission', () => {
  const defaultProps = {
    submissionId: 'submission-123',
    submissionType: 'online_upload',
    attachmentId: 'attachment-456',
  }

  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      FEATURES: {lti_asset_processor: true},
    }
    queryClient.clear()
  })

  it('returns null when no data is available', () => {
    // No query data set, so hook returns undefined
    const {container} = render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    expect(container.firstChild).toBeNull()
  })

  it('renders "Please review" status when reports have high priority', () => {
    // Set up query data with high priority reports
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: defaultProps.attachmentId,
      attachmentName: 'test-file.pdf',
    })

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('Please review')).toBeInTheDocument()
  })

  it('opens modal when "Please review" link is clicked', async () => {
    const user = userEvent.setup()

    // Set up query data with reports and processors
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: defaultProps.attachmentId,
      attachmentName: 'important-document.pdf',
      assignmentName: 'Essay Assignment',
    })

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    // Click the "Please review" link
    const needsAttentionLink = screen.getByText('Please review')
    await user.click(needsAttentionLink)

    // Modal should be opened with the assignment name
    expect(screen.getByText('Document Processors for Essay Assignment')).toBeInTheDocument()
  })

  it('displays correct report information in modal', async () => {
    const user = userEvent.setup()

    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: defaultProps.attachmentId,
      attachmentName: 'research-paper.docx',
      assignmentName: 'Research Project',
    })

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    // Open the modal
    await user.click(screen.getByText('Please review'))

    // Check that the modal contains report information
    expect(screen.getByText('Document Processors for Research Project')).toBeInTheDocument()
    expect(screen.getByText('research-paper.docx')).toBeInTheDocument()
  })

  it('closes modal when onClose is called', async () => {
    const user = userEvent.setup()

    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: defaultProps.attachmentId,
      attachmentName: 'test-file.pdf',
      assignmentName: 'Test Assignment',
    })

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    // Open modal
    await user.click(screen.getByText('Please review'))
    expect(screen.getByText('Document Processors for Test Assignment')).toBeInTheDocument()

    // Close modal (look for close button)
    const closeButton = screen.getAllByRole('button', {name: /close/i})[0]
    await user.click(closeButton)

    // Modal should be closed
    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })

  it('renders with attachmentId filtering', () => {
    // Create data with reports for the specific attachmentId
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: defaultProps.attachmentId,
      attachmentName: 'target-file.pdf',
    })

    // Add additional reports with different attachment IDs
    const additionalReports = mockData.submission!.ltiAssetReportsConnection!.nodes!.map(
      report => ({
        ...report!,
        _id: 'report-other-' + report!._id,
        asset: {
          attachmentId: 'other-attachment-id',
          submissionAttempt: 1,
          attachmentName: 'other-file.pdf',
        },
      }),
    )

    mockData.submission!.ltiAssetReportsConnection!.nodes = [
      ...mockData.submission!.ltiAssetReportsConnection!.nodes!,
      ...additionalReports,
    ]

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    // Should render status (the component filters by attachmentId internally)
    expect(screen.getByText('Please review')).toBeInTheDocument()
  })

  it('renders "No result" when attachmentId has no matching reports', () => {
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult({
      attachmentId: 'different-attachment-id', // Different from props
      attachmentName: 'different-file.pdf',
    })

    queryClient.setQueryData(
      ['ltiAssetProcessorsAndReportsForStudent', defaultProps.submissionId],
      mockData,
    )

    render(
      <MockedQueryProvider>
        <LtiAssetReportsForStudentSubmission {...defaultProps} />
      </MockedQueryProvider>,
    )

    // No reports match the attachmentId, so "No result" should be shown
    expect(screen.getByText('No result')).toBeInTheDocument()
  })
})
