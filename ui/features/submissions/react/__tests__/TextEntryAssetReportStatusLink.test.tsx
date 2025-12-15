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
import {type MockedFunction} from 'vitest'
import TextEntryAssetReportStatusLink from '../TextEntryAssetReportStatusLink'
import {useShouldShowLtiAssetReportsForStudent} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'

// Mock the hooks
vi.mock('@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent')

// Mock the child component
vi.mock('@canvas/lti-asset-processor/react/LtiAssetReportsForStudentSubmission', () => {
  return {
    LtiAssetReportsForStudentSubmission: function MockComponent(props: any) {
      return (
        <div data-testid="asset-reports-component">
          <div data-testid="submission-id">{props.submissionId}</div>
          <div data-testid="submission-type">{props.submissionType}</div>
        </div>
      )
    },
  }
})

// Mock i18n
vi.mock('@canvas/i18n', () => ({
  useScope: () => ({
    t: (key: string) => key,
  }),
}))

const mockUseShouldShowLtiAssetReportsForStudent =
  useShouldShowLtiAssetReportsForStudent as MockedFunction<
    typeof useShouldShowLtiAssetReportsForStudent
  >

describe('TextEntryAssetReportStatusLink', () => {
  const defaultProps = {
    submissionId: '123',
    submissionType: 'online_text_entry',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders when shouldShow is true', () => {
    mockUseShouldShowLtiAssetReportsForStudent.mockReturnValue(true)

    render(<TextEntryAssetReportStatusLink {...defaultProps} />)

    expect(screen.getByText('Document Processors:')).toBeInTheDocument()
    expect(screen.getByTestId('asset-reports-component')).toBeInTheDocument()
    expect(screen.getByTestId('submission-id')).toHaveTextContent('123')
    expect(screen.getByTestId('submission-type')).toHaveTextContent('online_text_entry')
    expect(mockUseShouldShowLtiAssetReportsForStudent).toHaveBeenCalledWith({
      submissionId: '123',
      submissionType: 'online_text_entry',
    })
  })

  it('does not render when shouldShow is false', () => {
    mockUseShouldShowLtiAssetReportsForStudent.mockReturnValue(false)

    const {container} = render(<TextEntryAssetReportStatusLink {...defaultProps} />)

    expect(container).toBeEmptyDOMElement()
    expect(screen.queryByText('Document Processors:')).not.toBeInTheDocument()
    expect(screen.queryByTestId('asset-reports-component')).not.toBeInTheDocument()
  })
})
