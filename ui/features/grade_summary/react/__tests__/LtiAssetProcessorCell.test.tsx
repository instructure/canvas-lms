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
import LtiAssetProcessorCell from '../LtiAssetProcessorCell'
import {
  LtiAssetProcessor,
  LtiAssetReportForStudent,
} from '@canvas/lti-asset-processor/model/LtiAssetReport'

describe('LtiAssetProcessorCell', () => {
  const mockAssetProcessors: LtiAssetProcessor[] = [
    {
      _id: '1',
      title: 'Test Asset Processor',
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '2',
        name: 'Test Tool',
        labelFor: null,
      },
    },
  ]

  const createMockAssetReport = (
    priority: number = 0,
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
      attachmentId: '10',
      attachmentName: 'test.pdf',
      submissionAttempt: 1,
      discussionEntryVersion: null,
    },
    ...overrides,
  })

  it('renders with empty asset reports array', () => {
    render(
      <LtiAssetProcessorCell
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
      <LtiAssetProcessorCell
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
      <LtiAssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={mockAssetReports}
        submissionType="online_upload"
        assignmentName="Test Assignment"
      />,
    )

    await user.click(screen.getByText('All good'))

    expect(screen.getByText('Document Processors for Test Assignment')).toBeInTheDocument()

    await user.click(screen.getAllByRole('button', {name: /close/i})[0])

    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })

  it('infers discussion_topic submission type for discussion-based asset reports', () => {
    const mockDiscussionAssetReports = [
      createMockAssetReport(0, {
        asset: {
          attachmentId: null,
          attachmentName: null,
          submissionAttempt: 1,
          discussionEntryVersion: {
            __typename: 'DiscussionEntryVersion',
            _id: 'entry_123',
            messageIntro: 'This is a test discussion entry',
            createdAt: '2025-01-15T16:45:00Z',
          },
        },
      }),
    ]

    render(
      <LtiAssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={mockDiscussionAssetReports}
        submissionType={undefined}
        assignmentName="Test Assignment"
      />,
    )

    expect(screen.getByText('All good')).toBeInTheDocument()
  })

  it('does not render when submission type is null and no discussion reports exist', () => {
    const mockNonDiscussionAssetReports = [
      createMockAssetReport(0, {
        asset: {
          attachmentId: '10',
          attachmentName: 'test.pdf',
          submissionAttempt: 1,
          discussionEntryVersion: null,
        },
      }),
    ]

    const {container} = render(
      <LtiAssetProcessorCell
        assetProcessors={mockAssetProcessors}
        assetReports={mockNonDiscussionAssetReports}
        submissionType={undefined}
        assignmentName="Test Assignment"
      />,
    )

    expect(container).toBeEmptyDOMElement()
  })
})
