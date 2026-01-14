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
import React from 'react'
import {type MockedFunction} from 'vitest'
import DocumentProcessorsSection from '../DocumentProcessorsSection'
import {useShouldShowLtiAssetReportsForStudent} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'

// Mock the hook
vi.mock(
  '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent',
  () => ({
    useShouldShowLtiAssetReportsForStudent: vi.fn(),
  }),
)

// Mock the component
vi.mock('@canvas/lti-asset-processor/react/LtiAssetReportsForStudentSubmission', () => {
  return {
    LtiAssetReportsForStudentSubmission: vi.fn(({submissionId, submissionType}) => (
      <div data-testid="lti-asset-reports">
        Mock LTI Asset Reports for {submissionId} ({submissionType})
      </div>
    )),
  }
})

const mockUseShouldShow = useShouldShowLtiAssetReportsForStudent as MockedFunction<
  typeof useShouldShowLtiAssetReportsForStudent
>

describe('DocumentProcessorsSection', () => {
  const mockSubmission = {
    submissionId: 'test-submission-123',
    submissionType: 'online_upload',
    ifLastAttemptIsNumber: 1,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders LtiAssetReportsForStudentSubmission when there is data', () => {
    mockUseShouldShow.mockReturnValue(true)

    render(<DocumentProcessorsSection submission={mockSubmission} />)

    expect(screen.getByText('Document processors')).toBeInTheDocument()
    expect(screen.getByTestId('lti-asset-reports')).toBeInTheDocument()
    expect(
      screen.getByText('Mock LTI Asset Reports for test-submission-123 (online_upload)'),
    ).toBeInTheDocument()

    expect(mockUseShouldShow).toHaveBeenCalledWith(mockSubmission)
  })

  it('does not render when there is no data', () => {
    mockUseShouldShow.mockReturnValue(false)

    const {container} = render(<DocumentProcessorsSection submission={mockSubmission} />)

    expect(container.firstChild).toBeNull()
    expect(screen.queryByText('Document processors')).not.toBeInTheDocument()
    expect(screen.queryByTestId('lti-asset-reports')).not.toBeInTheDocument()
  })
})
