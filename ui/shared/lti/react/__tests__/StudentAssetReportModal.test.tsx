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
import {LtiAssetReportWithAsset} from '@canvas/lti/model/AssetReport'

describe('StudentAssetReportModal', () => {
  const createReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    assetAttachmentId: string = '10',
    assetAttachmentName: string = 'test.pdf',
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
      attachment_id: assetAttachmentId,
      attachment_name: assetAttachmentName,
      submission_id: '1000',
      submission_attempt: '1',
    },
    ...overrides,
  })

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
    const reports = [createReport(0, '', 'test.pdf')]

    const {container} = render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
      />,
    )

    expect(container.firstChild).toBeNull()
  })

  it('renders the modal when open prop is true', () => {
    const reports = [createReport()]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
      />,
    )

    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })

  it('does not render the modal when open prop is false', () => {
    const reports = [createReport()]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={false}
      />,
    )

    expect(screen.queryByText(`Document Processors for ${assignmentName}`)).not.toBeInTheDocument()
  })

  it('renders the attachment name', () => {
    const attachmentName = 'important_file.pdf'
    const reports = [createReport(0, '10', attachmentName)]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
      />,
    )

    expect(screen.getByText(attachmentName)).toBeInTheDocument()
  })

  it('filters asset processors to only include those with reports', () => {
    const reports = [
      createReport(0, '10', 'test.pdf', {asset_processor_id: 1}),
      createReport(1, '10', 'test.pdf', {asset_processor_id: 2}),
    ]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
      />,
    )

    expect(screen.getByText('Test Processor · Test Processor Title')).toBeInTheDocument()
    expect(screen.getByText('Another Processor · Another Processor Title')).toBeInTheDocument()
    expect(screen.queryByText('Unused Processor · Unused Processor Title')).not.toBeInTheDocument()
  })

  it('properly renders with reports from multiple processors', () => {
    const reports = [
      createReport(0, '10', 'test.pdf', {asset_processor_id: 1}),
      createReport(1, '10', 'test.pdf', {asset_processor_id: 2}),
    ]

    render(
      <StudentAssetReportModal
        assetProcessors={mockAssetProcessors}
        assignmentName={assignmentName}
        reports={reports}
        open={true}
      />,
    )

    expect(screen.getByText('test.pdf')).toBeInTheDocument()
    expect(screen.getByText('Needs attention')).toBeInTheDocument()
    expect(screen.getByText(`Document Processors for ${assignmentName}`)).toBeInTheDocument()
  })
})
