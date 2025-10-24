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

  it('filters asset processors to only include those with reports', () => {
    const reports = [
      createUploadReport(0, '10', {processorId: '1'}),
      createUploadReport(1, '10', {processorId: '2'}),
    ]

    const attachments = [{_id: '10', displayName: 'test.pdf'}]

    render(
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
})
