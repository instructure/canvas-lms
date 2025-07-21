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

import StudentAssetReportModal from '../StudentAssetReportModal'
import {render, screen} from '@testing-library/react'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

describe('StudentAssetReportModal', () => {
  const createBaseReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    assetOverrides: Partial<LtiAssetReportWithAsset['asset']> = {},
    overrides: Partial<LtiAssetReportWithAsset> = {},
  ): LtiAssetReportWithAsset => ({
    // LtiAssetReport properties
    _id: 123,
    priority,
    reportType: 'plagiarism',
    resubmitAvailable: false,
    processingProgress: 'Processed',
    // Extended properties from LtiAssetReportWithAsset
    asset_processor_id: 1,
    asset: {
      id: 100,
      attachment_id: null,
      attachment_name: null,
      submission_id: '1000',
      submission_attempt: null,
      ...assetOverrides,
    },
    ...overrides,
  })

  const createUploadReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    assetAttachmentId: string = '10',
    assetAttachmentName: string = 'test.pdf',
    overrides: Partial<LtiAssetReportWithAsset> = {},
  ): LtiAssetReportWithAsset =>
    createBaseReport(
      priority,
      {
        attachment_id: assetAttachmentId,
        attachment_name: assetAttachmentName,
      },
      overrides,
    )

  const createTextEntryReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    submissionAttempt: string = '1',
    overrides: Partial<LtiAssetReportWithAsset> = {},
  ): LtiAssetReportWithAsset =>
    createBaseReport(
      priority,
      {
        submission_attempt: submissionAttempt,
      },
      overrides,
    )

  const mockAssetProcessors = [
    {
      id: 1,
      tool_id: 101,
      tool_name: 'Test Processor',
      title: 'Test Processor Title',
    },
    {
      id: 2,
      tool_id: 101,
      tool_name: 'Another Processor',
      title: 'Another Processor Title',
    },
    {
      id: 3,
      tool_id: 103,
      tool_name: 'Unused Processor',
      title: 'Unused Processor Title',
    },
  ]
  const assignmentName = 'Test Assignment'

  it('renders nothing when reports have no attachmentId', () => {
    const reports = [createUploadReport(0, '', 'test.pdf')]

    const {container} = render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    expect(container.firstChild).toBeNull()
  })

  it('renders the modal when open prop is true', () => {
    const reports = [createUploadReport()]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })

  it('does not render the modal when open prop is false', () => {
    const reports = [createUploadReport()]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={false}
        submissionType="online_upload"
      />,
    )

    expect(screen.queryByText(`Document Processors for ${assignmentName}`)).not.toBeInTheDocument()
  })

  it('renders the attachment name', () => {
    const attachmentName = 'important_file.pdf'
    const reports = [createUploadReport(0, '10', attachmentName)]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText(attachmentName)).toBeInTheDocument()
  })

  it('filters asset processors to only include those with reports', () => {
    const reports = [
      createUploadReport(0, '10', 'test.pdf', {asset_processor_id: 1}),
      createUploadReport(1, '10', 'test.pdf', {asset_processor_id: 2}),
    ]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
    expect(screen.getByText('Another Processor · Another Processor Title')).toBeInTheDocument()
    expect(screen.queryByText('Unused Processor · Unused Processor Title')).not.toBeInTheDocument()
  })

  it('properly renders with reports from multiple processors', () => {
    const reports = [
      createUploadReport(0, '10', 'test.pdf', {asset_processor_id: 1}),
      createUploadReport(1, '10', 'test.pdf', {asset_processor_id: 2}),
    ]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText('test.pdf')).toBeInTheDocument()
    expect(screen.getByText('Needs attention')).toBeInTheDocument()
    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })

  it('handles multiple attachments with multiple reports per attachment', () => {
    const reports = [
      // Reports for first attachment (document.pdf)
      createUploadReport(0, '10', 'document.pdf', {
        asset_processor_id: 1,
        _id: 101,
        reportType: 'plagiarism',
      }),
      createUploadReport(2, '10', 'document.pdf', {
        asset_processor_id: 1,
        _id: 102,
        reportType: 'similarity',
      }),

      // Reports for second attachment (essay.docx)
      createUploadReport(1, '20', 'essay.docx', {
        asset_processor_id: 1,
        _id: 201,
        reportType: 'plagiarism',
      }),
      createUploadReport(0, '20', 'essay.docx', {
        asset_processor_id: 1,
        _id: 202,
        reportType: 'similarity',
      }),

      // Reports for third attachment (presentation.pptx)
      createUploadReport(3, '30', 'presentation.pptx', {
        asset_processor_id: 1,
        _id: 301,
        reportType: 'plagiarism',
      }),
    ]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
        submissionType="online_upload"
      />,
    )

    // Should show all attachment names since there are multiple attachments
    expect(screen.getByText('document.pdf')).toBeInTheDocument()
    expect(screen.getByText('essay.docx')).toBeInTheDocument()
    expect(screen.getByText('presentation.pptx')).toBeInTheDocument()

    expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()

    // Should show the overall status reflecting the highest priority (3 = high priority)
    expect(screen.getByText('Needs attention')).toBeInTheDocument()
    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })

  describe('with online_text_entry submission type', () => {
    it('renders the modal with text entry label', () => {
      const reports = [createTextEntryReport()]

      render(
        <StudentAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          open={true}
          submissionType="online_text_entry"
        />,
      )

      expect(screen.getAllByText('Text submitted to Canvas')[0]).toBeInTheDocument()
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
    })

    it('filters asset processors for text entries same as for uploads', () => {
      const reports = [
        createTextEntryReport(0, '1', {asset_processor_id: 1}),
        createTextEntryReport(1, '1', {asset_processor_id: 2}),
      ]

      render(
        <StudentAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          open={true}
          submissionType="online_text_entry"
        />,
      )

      expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
      expect(screen.getByText('Another Processor · Another Processor Title')).toBeInTheDocument()
      expect(
        screen.queryByText('Unused Processor · Unused Processor Title'),
      ).not.toBeInTheDocument()
    })

    it('renders correctly even when submission_attempt is null', () => {
      const reports = [
        createTextEntryReport(0, null as any, {
          asset_processor_id: 1,
        }),
      ]

      render(
        <StudentAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          open={true}
          submissionType="online_text_entry"
        />,
      )

      expect(screen.getAllByText('Text submitted to Canvas')[0]).toBeInTheDocument()
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
    })
  })
})
