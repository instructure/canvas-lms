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

import '../../../__tests__/mockedDependenciesShims'
import {screen} from '@testing-library/react'
import {renderComponent} from '../../../__tests__/renderingShims'
import {fn} from '../../../__tests__/testPlatformShims'
import {useResubmitDiscussionNotices} from '../../../dependenciesShims'
import type {LtiAssetProcessor} from '../../types/LtiAssetProcessors'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import {AssetReportModal} from '../AssetReportModal'

describe('AssetReportModal', () => {
  const createBaseReport = (
    priority: number = 0,
    assetOverrides: Partial<LtiAssetReport['asset']> = {},
    overrides: Partial<LtiAssetReport> = {},
  ): LtiAssetReport => ({
    _id: '123',
    priority,
    resubmitAvailable: false,
    processingProgress: 'Processed',
    processorId: '1',
    comment: null,
    errorCode: null,
    indicationAlt: null,
    indicationColor: null,
    launchUrlPath: null,
    result: null,
    resultTruncated: null,
    title: null,
    asset: {
      attachmentId: null,
      submissionAttempt: null,
      ...assetOverrides,
    },
    ...overrides,
  })

  const createUploadReport = (
    priority: number = 0,
    assetAttachmentId: string = '10',
    overrides: Partial<LtiAssetReport> = {},
  ): LtiAssetReport =>
    createBaseReport(
      priority,
      {
        attachmentId: assetAttachmentId,
      },
      overrides,
    )

  const mockAssetProcessors: LtiAssetProcessor[] = [
    {
      _id: '1',
      title: 'Test Processor Title',
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '101',
        name: 'Test Processor',
        labelFor: null,
      },
    },
    {
      _id: '2',
      title: 'Another Processor Title',
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '101',
        name: 'Another Processor',
        labelFor: null,
      },
    },
    {
      _id: '3',
      title: 'Unused Processor Title',
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '103',
        name: 'Unused Processor',
        labelFor: null,
      },
    },
  ]

  const mockOnClose = fn()

  beforeEach(() => {
    mockOnClose.mockClear()
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: fn(),
      isIdle: true,
      isError: false,
      variables: undefined,
    })
  })

  it('filters asset processors to only include those with reports', () => {
    const reports = [
      createUploadReport(0, '10', {processorId: '1'}),
      createUploadReport(1, '10', {processorId: '2'}),
    ]

    const attachments = [{_id: '10', displayName: 'test.pdf'}]

    renderComponent(
      <AssetReportModal
        assetProcessors={mockAssetProcessors}
        modalTitle="Test Modal"
        attachments={attachments}
        attempt=""
        mainTitle={undefined}
        reports={reports}
        showDocumentDisplayName={false}
        studentIdForResubmission={undefined}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
    expect(screen.getByText('Another Processor · Another Processor Title')).toBeInTheDocument()
    expect(screen.queryByText('Unused Processor · Unused Processor Title')).not.toBeInTheDocument()
  })

  it('renders close buttons in header and footer', () => {
    const reports = [createUploadReport(0, '10', {processorId: '1'})]
    const attachments = [{_id: '10', displayName: 'test.pdf'}]

    renderComponent(
      <AssetReportModal
        assetProcessors={mockAssetProcessors}
        modalTitle="Test Modal"
        onClose={mockOnClose}
        attachments={attachments}
        attempt=""
        mainTitle={undefined}
        reports={reports}
        showDocumentDisplayName={false}
        studentIdForResubmission={undefined}
        submissionType="online_upload"
      />,
    )

    // There should be two close buttons - one in header (X) and one in footer
    const closeButtons = screen.getAllByText('Close')
    expect(closeButtons).toHaveLength(2)
  })

  it('calls onClose when footer close button is clicked', () => {
    const reports = [createUploadReport(0, '10', {processorId: '1'})]
    const attachments = [{_id: '10', displayName: 'test.pdf'}]

    renderComponent(
      <AssetReportModal
        assetProcessors={mockAssetProcessors}
        modalTitle="Test Modal"
        onClose={mockOnClose}
        attachments={attachments}
        attempt=""
        mainTitle={undefined}
        reports={reports}
        showDocumentDisplayName={false}
        studentIdForResubmission={undefined}
        submissionType="online_upload"
      />,
    )

    expect(mockOnClose).toHaveBeenCalledTimes(0)
    const closeButtons = screen.getAllByText('Close')
    // Click the footer close button (the second one)
    closeButtons[1]?.click()
    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('displays mainTitle when provided', () => {
    const reports = [createUploadReport(0, '10', {processorId: '1'})]
    const attachments = [{_id: '10', displayName: 'test.pdf'}]

    renderComponent(
      <AssetReportModal
        assetProcessors={mockAssetProcessors}
        modalTitle="Test Modal"
        onClose={mockOnClose}
        attachments={attachments}
        attempt=""
        mainTitle="Assignment Title"
        reports={reports}
        showDocumentDisplayName={false}
        studentIdForResubmission={undefined}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText('Assignment Title')).toBeInTheDocument()
  })

  describe('Resubmit All Replies button', () => {
    const createDiscussionReport = (
      priority: number = 0,
      overrides: Partial<LtiAssetReport> = {},
    ): LtiAssetReport =>
      createBaseReport(
        priority,
        {
          discussionEntryVersion: {
            _id: 'entry_123',
            createdAt: '2025-01-15T16:45:00Z',
            messageIntro: 'Test discussion entry',
          },
        },
        overrides,
      )

    it('shows Resubmit All Replies button for discussions', () => {
      const reports: LtiAssetReport[] = [
        createDiscussionReport(0, {processorId: '1', resubmitAvailable: true}),
        createDiscussionReport(1, {processorId: '2', resubmitAvailable: false}),
      ]

      renderComponent(
        <AssetReportModal
          assetProcessors={mockAssetProcessors}
          modalTitle="Test Modal"
          onClose={mockOnClose}
          attachments={[]}
          attempt=""
          mainTitle={undefined}
          reports={reports}
          showDocumentDisplayName={false}
          studentIdForResubmission="456"
          submissionType="discussion_topic"
          assignmentId="123"
        />,
      )

      expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
      expect(screen.queryByText('Resubmit All Files')).not.toBeInTheDocument()
    })

    it('hides button when studentIdForResubmission is not provided', () => {
      const reports = [createDiscussionReport(0, {processorId: '1', resubmitAvailable: true})]

      renderComponent(
        <AssetReportModal
          assetProcessors={mockAssetProcessors}
          modalTitle="Test Modal"
          onClose={mockOnClose}
          attachments={[]}
          attempt=""
          mainTitle={undefined}
          reports={reports}
          showDocumentDisplayName={false}
          studentIdForResubmission={undefined}
          submissionType="discussion_topic"
          assignmentId="123"
        />,
      )

      expect(screen.queryByText('Resubmit All Replies')).not.toBeInTheDocument()
    })

    it('hides button when assignmentId is not provided', () => {
      const reports = [createDiscussionReport(0, {processorId: '1', resubmitAvailable: true})]

      renderComponent(
        <AssetReportModal
          assetProcessors={mockAssetProcessors}
          modalTitle="Test Modal"
          onClose={mockOnClose}
          attachments={[]}
          attempt=""
          mainTitle={undefined}
          reports={reports}
          showDocumentDisplayName={false}
          studentIdForResubmission="456"
          submissionType="discussion_topic"
          assignmentId={undefined}
        />,
      )

      expect(screen.queryByText('Resubmit All Replies')).not.toBeInTheDocument()
    })

    it('hides button for non-discussion submissions', () => {
      const reports = [createUploadReport(0, '10', {processorId: '1', resubmitAvailable: true})]
      const attachments = [{_id: '10', displayName: 'test.pdf'}]

      renderComponent(
        <AssetReportModal
          assetProcessors={mockAssetProcessors}
          modalTitle="Test Modal"
          onClose={mockOnClose}
          attachments={attachments}
          attempt=""
          mainTitle={undefined}
          reports={reports}
          showDocumentDisplayName={false}
          studentIdForResubmission="456"
          submissionType="online_upload"
          assignmentId="123"
        />,
      )

      expect(screen.queryByText('Resubmit All Replies')).not.toBeInTheDocument()
      // Should show the regular resubmit button instead
      expect(screen.getByText('Resubmit All Files')).toBeInTheDocument()
    })
  })
})
