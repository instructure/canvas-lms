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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssetProcessorCell from '../AssetProcessorCell'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

describe('AssetProcessorCell', () => {
  const mockAssetProcessors: ExistingAttachedAssetProcessor[] = [
    {
      id: 1,
      tool_id: 2,
      tool_name: 'Test Tool',
      title: 'Test Asset Processor',
    },
  ]

  const createMockAssetReport = (
    priority: 0 | 1 | 2 | 3 | 4 | 5 = 0,
    overrides: Partial<LtiAssetReportWithAsset> = {},
  ): LtiAssetReportWithAsset => ({
    _id: 123,
    priority,
    reportType: 'plagiarism',
    resubmitAvailable: false,
    processingProgress: 'Processed',
    asset_processor_id: 1,
    asset: {
      id: 100,
      attachment_id: '10',
      attachment_name: 'test.pdf',
      submission_id: '1000',
      submission_attempt: '1',
    },
    ...overrides,
  })

  it('renders with empty asset reports array', () => {
    render(
      <AssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={[]}
        submissionType="online_upload"
        assignmentName="Test Assignment"
      />,
    )

    expect(screen.getByText('No result')).toBeInTheDocument()
  })

  it('opens modal when status link is clicked', async () => {
    const user = userEvent.setup()
    const mockAssetReports = [createMockAssetReport(0)]

    render(
      <AssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={mockAssetReports}
        submissionType="online_upload"
        assignmentName="Test Assignment"
      />,
    )

    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()

    await user.click(screen.getByText('All good'))

    expect(screen.getByText('Document Processors for Test Assignment')).toBeInTheDocument()
    expect(screen.getByText('Test Tool · Test Asset Processor')).toBeInTheDocument()
    expect(screen.getByText('test.pdf')).toBeInTheDocument()
  })

  it('closes modal when close button is clicked', async () => {
    const user = userEvent.setup()
    const mockAssetReports = [createMockAssetReport(0)]

    render(
      <AssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={mockAssetReports}
        submissionType="online_upload"
        assignmentName="Test Assignment"
      />,
    )

    await user.click(screen.getByText('All good'))

    expect(screen.getByText('Document Processors for Test Assignment')).toBeInTheDocument()

    await user.click(screen.getByRole('button', {name: /close/i}))

    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })
})
