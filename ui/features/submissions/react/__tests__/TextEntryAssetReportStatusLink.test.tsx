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

import TextEntryAssetReportStatusLink from '../TextEntryAssetReportStatusLink'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

describe('TextEntryAssetReportStatusLink', () => {
  const createReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    submissionAttempt: string = '1',
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
      attachment_name: 'text_entry',
      submission_id: '1000',
      submission_attempt: submissionAttempt,
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

  it('filters reports by attempt', () => {
    const attempt = '1'
    const reports = [
      createReport(0, '1'),
      createReport(1, '2'), // Should be filtered out
      createReport(0, '1'),
    ]

    render(
      <TextEntryAssetReportStatusLink
        assetProcessors={mockAssetProcessors}
        reports={reports}
        attempt={attempt}
        assignmentName={assignmentName}
      />,
    )

    // Verify that 'All good' status is shown (since no filtered reports have high priority)
    expect(screen.getByText('All good')).toBeInTheDocument()
    expect(screen.getByText('Document Processors:')).toBeInTheDocument()
  })

  it('opens modal when link is clicked', async () => {
    const attempt = '1'
    const reports = [createReport(0, '1')]
    const user = userEvent.setup()

    render(
      <TextEntryAssetReportStatusLink
        assetProcessors={mockAssetProcessors}
        reports={reports}
        attempt={attempt}
        assignmentName={assignmentName}
      />,
    )

    await user.click(screen.getByText('All good'))
    expect(screen.getByText('Document Processors for Test Assignment')).toBeInTheDocument()

    await user.click(screen.getByRole('button', {name: 'Close'}))
    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })

  it('renders nothing when no reports are available', () => {
    const attempt = '1'
    const reports: LtiAssetReportWithAsset[] = []

    render(
      <TextEntryAssetReportStatusLink
        assetProcessors={mockAssetProcessors}
        reports={reports}
        attempt={attempt}
        assignmentName={assignmentName}
      />,
    )

    expect(screen.getByText('No result')).toBeInTheDocument()
  })
})
