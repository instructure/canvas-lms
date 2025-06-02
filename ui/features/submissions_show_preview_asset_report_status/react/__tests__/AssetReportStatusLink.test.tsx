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

import AssetReportStatusLink, {ASSET_REPORT_MODAL_EVENT} from '../AssetReportStatusLink'
import {LtiAssetReportWithAsset} from '@canvas/lti/model/AssetReport'
import {render, screen} from '@testing-library/react'

describe('AssetReportStatusLink', () => {
  const createReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    assetAttachmentId: string | null = '10',
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
      attachment_name: 'test.pdf',
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
  ]
  const assignmentName = 'Test Assignment'

  let originalPostMessage: typeof window.parent.postMessage

  beforeEach(() => {
    originalPostMessage = window.parent.postMessage
    window.parent.postMessage = jest.fn()
    // Clear mock counts before each test
    jest.clearAllMocks()
  })

  afterEach(() => {
    window.parent.postMessage = originalPostMessage
  })

  it('filters reports by attachmentId', () => {
    const attachmentId = '10'
    const reports = [
      createReport(0, '10'),
      createReport(1, '20'), // Should be filtered out
      createReport(0, '10'),
    ]

    render(
      <AssetReportStatusLink
        assetProcessors={mockAssetProcessors}
        assetReports={reports}
        attachmentId={attachmentId}
        assignmentName={assignmentName}
      />,
    )

    // Verify that 'All good' status is shown (since no filtered reports have high priority)
    expect(screen.getByText('All good')).toBeInTheDocument()
  })

  it('calls postMessage with correct data when openModal is triggered', async () => {
    const attachmentId = '10'
    const reports = [
      createReport(0, '10'),
      createReport(1, '20'), // Should be filtered out
      createReport(0, '10'),
    ]

    // Get the openModal function that was passed to AssetReportStatus
    render(
      <AssetReportStatusLink
        assetProcessors={mockAssetProcessors}
        assetReports={reports}
        attachmentId={attachmentId}
        assignmentName={assignmentName}
      />,
    )

    screen.getByText('All good').click()

    const filteredReports = reports.filter(report => report.asset.attachment_id === attachmentId)
    // Verify window.parent.postMessage was called with correct data
    expect(window.parent.postMessage).toHaveBeenCalledWith({
      type: ASSET_REPORT_MODAL_EVENT,
      assetReports: filteredReports,
      assetProcessors: mockAssetProcessors,
      assignmentName,
    })
  })
})
