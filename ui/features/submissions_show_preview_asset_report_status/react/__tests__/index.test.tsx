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
import {type MockedFunction} from 'vitest'
import AttachmentAssetReportStatus from '../index'
import {ASSET_REPORT_MODAL_EVENT} from '@canvas/lti-asset-processor/react/StudentAssetReportModalWrapper'
import {render, screen} from '@testing-library/react'
import {useLtiAssetProcessorsAndReportsForStudent} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'
import {defaultLtiAssetProcessors} from '@canvas/lti-asset-processor/shared-with-sg/replicated/__fixtures__/default/ltiAssetProcessors'
import {defaultLtiAssetReportsForStudent} from '@canvas/lti-asset-processor/queries/__fixtures__/LtiAssetProcessorsAndReportsForStudent'

vi.mock('@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent')

const mockUseLtiAssetProcessorsAndReportsForStudent =
  useLtiAssetProcessorsAndReportsForStudent as MockedFunction<
    typeof useLtiAssetProcessorsAndReportsForStudent
  >

describe('AttachmentAssetReportStatus', () => {
  const assignmentName = 'Test Assignment'

  let originalPostMessage: typeof window.parent.postMessage

  beforeEach(() => {
    originalPostMessage = window.parent.postMessage
    window.parent.postMessage = vi.fn()
    // Clear mock counts before each test
    vi.clearAllMocks()

    const mockReports = defaultLtiAssetReportsForStudent({attachmentId: '10'}).slice(0, 2)

    mockUseLtiAssetProcessorsAndReportsForStudent.mockReturnValue({
      assignmentName,
      attempt: 1,
      submissionType: 'online_upload',
      assetProcessors: defaultLtiAssetProcessors,
      reports: mockReports,
    })
  })

  afterEach(() => {
    window.parent.postMessage = originalPostMessage
  })

  it('gets data from useLtiAssetProcessorsAndReportsForStudent', () => {
    render(
      <AttachmentAssetReportStatus
        submissionType="online_upload"
        submissionId="1000"
        attachmentId="10"
      />,
    )

    expect(screen.getByText('Please review')).toBeInTheDocument()
    expect(mockUseLtiAssetProcessorsAndReportsForStudent).toHaveBeenCalledWith({
      submissionId: '1000',
      submissionType: 'online_upload',
      attachmentId: '10',
    })
  })

  it('calls postMessage with correct data when openModal is triggered', async () => {
    render(
      <AttachmentAssetReportStatus
        submissionType="online_upload"
        submissionId="1000"
        attachmentId="10"
      />,
    )

    screen.getByText('Please review').click()

    // Verify window.parent.postMessage was called with correct data
    expect(window.parent.postMessage).toHaveBeenCalledWith(
      {
        type: ASSET_REPORT_MODAL_EVENT,
        assignmentName,
        attempt: 1,
        submissionType: 'online_upload',
        assetProcessors: expect.arrayContaining([
          expect.objectContaining({
            _id: expect.any(String),
            externalTool: expect.objectContaining({
              name: expect.any(String),
            }),
          }),
        ]),
        reports: expect.arrayContaining([
          expect.objectContaining({
            _id: expect.any(String),
            asset: expect.objectContaining({
              attachmentId: '10',
            }),
          }),
        ]),
      },
      window.location.origin,
    )
  })
})
