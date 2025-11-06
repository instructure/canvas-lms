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

import StudentLtiAssetReportModal from '../StudentLtiAssetReportModal'
import {render, screen} from '@testing-library/react'
import {
  LtiAssetProcessor,
  LtiAssetReportForStudent,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'

describe('StudentLtiAssetReportModal', () => {
  const createBaseReport = (
    priority: number = 0,
    assetOverrides: Partial<LtiAssetReportForStudent['asset']> = {},
    overrides: Partial<LtiAssetReportForStudent> = {},
  ): LtiAssetReportForStudent => ({
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
      attachmentName: null,
      submissionAttempt: null,
      ...assetOverrides,
    },
    ...overrides,
  })

  const createUploadReport = (
    priority: number = 0,
    assetAttachmentId: string = '10',
    assetAttachmentName: string = 'test.pdf',
    overrides: Partial<LtiAssetReportForStudent> = {},
  ): LtiAssetReportForStudent =>
    createBaseReport(
      priority,
      {
        attachmentId: assetAttachmentId,
        attachmentName: assetAttachmentName,
      },
      overrides,
    )

  const createTextEntryReport = (
    priority: number = 0,
    submissionAttempt: number = 1,
    overrides: Partial<LtiAssetReportForStudent> = {},
  ): LtiAssetReportForStudent =>
    createBaseReport(
      priority,
      {
        submissionAttempt: submissionAttempt,
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
  const assignmentName = 'Test Assignment'

  it('renders nothing when reports have no attachmentId', () => {
    const reports = [createUploadReport(0, '', 'test.pdf')]

    const {container} = render(
      <StudentLtiAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        submissionType="online_upload"
      />,
    )

    expect(container.firstChild).toBeNull()
  })

  it('renders the modal', () => {
    const reports = [createUploadReport()]

    render(
      <StudentLtiAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })

  it('renders the attachment name', () => {
    const attachmentName = 'important_file.pdf'
    const reports = [createUploadReport(0, '10', attachmentName)]

    render(
      <StudentLtiAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        submissionType="online_upload"
      />,
    )

    expect(screen.getByText(attachmentName)).toBeInTheDocument()
  })

  it('properly renders with reports from multiple processors', () => {
    const reports = [
      createUploadReport(0, '10', 'test.pdf', {processorId: '1'}),
      createUploadReport(1, '10', 'test.pdf', {processorId: '2'}),
    ]

    render(
      <StudentLtiAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
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
        processorId: '1',
        _id: '101',
      }),
      createUploadReport(2, '10', 'document.pdf', {
        processorId: '1',
        _id: '102',
      }),

      // Reports for second attachment (essay.docx)
      createUploadReport(1, '20', 'essay.docx', {
        processorId: '1',
        _id: '201',
      }),
      createUploadReport(0, '20', 'essay.docx', {
        processorId: '1',
        _id: '202',
      }),

      // Reports for third attachment (presentation.pptx)
      createUploadReport(3, '30', 'presentation.pptx', {
        processorId: '1',
        _id: '301',
      }),
    ]

    render(
      <StudentLtiAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
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
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="online_text_entry"
        />,
      )

      expect(screen.getAllByText('Text submitted to Canvas')[0]).toBeInTheDocument()
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
    })

    it('filters asset processors for text entries same as for uploads', () => {
      const reports = [
        createTextEntryReport(0, 1, {processorId: '1'}),
        createTextEntryReport(1, 1, {processorId: '2'}),
      ]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
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
        createTextEntryReport(0, 1, {
          processorId: '1',
        }),
      ]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="online_text_entry"
        />,
      )

      expect(screen.getAllByText('Text submitted to Canvas')[0]).toBeInTheDocument()
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
    })
  })

  describe('with discussion_topic submission type', () => {
    it('renders the modal with "All comments" label for single report', () => {
      const reports = [createUploadReport(0, '10', 'attachment.pdf')]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="discussion_topic"
        />,
      )

      expect(screen.getByText('All comments')).toBeInTheDocument()
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
    })

    it('renders the modal for multiple reports', () => {
      const reports = [
        createUploadReport(0, '10', 'comment1.pdf', {processorId: '1'}),
        createUploadReport(1, '20', 'comment2.pdf', {processorId: '1'}),
      ]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="discussion_topic"
        />,
      )

      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
      expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
    })

    it('filters asset processors for discussion topics same as for uploads', () => {
      const reports = [
        createUploadReport(0, '10', 'test.pdf', {processorId: '1'}),
        createUploadReport(1, '10', 'test.pdf', {processorId: '2'}),
      ]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="discussion_topic"
        />,
      )

      expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
      expect(screen.getByText('Another Processor · Another Processor Title')).toBeInTheDocument()
      expect(
        screen.queryByText('Unused Processor · Unused Processor Title'),
      ).not.toBeInTheDocument()
    })

    it('renders correctly with reports containing attachments', () => {
      const reports = [createUploadReport(0, '10', 'discussion_attachment.pdf')]

      render(
        <StudentLtiAssetReportModal
          assetProcessors={mockAssetProcessors}
          assignmentName={assignmentName}
          reports={reports}
          submissionType="discussion_topic"
        />,
      )

      // Verify the modal renders without crashing when attachments are present
      expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
      expect(screen.getByText('All comments')).toBeInTheDocument()
    })
  })
})
