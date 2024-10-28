/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import FilesApp from '../FilesApp'
import {useQuery} from '@tanstack/react-query'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import friendlyBytes from '@canvas/files/util/friendlyBytes'

// Mock the `useQuery` hook from TanStack Query
jest.mock('@tanstack/react-query', () => ({
  useQuery: jest.fn(),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn().mockReturnValue(jest.fn()),
}))

describe('FilesApp', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders "Files" when contextAssetString starts with "course_"', () => {
    useQuery.mockReturnValue({data: null, isLoading: false, error: null})
    render(<FilesApp contextAssetString="course_12345" />)

    const headingElement = screen.getByText(/Files/i)
    expect(headingElement).toBeInTheDocument()
  })

  it('renders "All My Files" when contextAssetString starts with "user_"', () => {
    useQuery.mockReturnValue({data: null, isLoading: false, error: null})
    render(<FilesApp contextAssetString="user_67890" />)

    const headingElement = screen.getByText(/All My Files/i)
    expect(headingElement).toBeInTheDocument()
  })

  it('displays error message if quota fetch fails', () => {
    useQuery.mockReturnValue({data: null, isLoading: false, error: new Error('Failed to fetch')})
    render(<FilesApp contextAssetString="user_67890" />)

    expect(showFlashError).toHaveBeenCalledWith('An error occurred while loading files usage data')
  })

  it('renders progress bar with quota data when fetch is successful', async () => {
    useQuery.mockReturnValue({
      data: {quota_used: 500, quota: 1000},
      isLoading: false,
      error: null,
    })

    render(<FilesApp contextAssetString="user_67890" />)

    const quota = friendlyBytes('1000')
    const percentageText = await screen.findByText(`50% of ${quota} used`)
    expect(percentageText).toBeInTheDocument()

    const progressBar = screen.getByLabelText(/File Storage Quota Used/i)
    expect(progressBar).toHaveAttribute('aria-valuemax', '1000')
    expect(progressBar).toHaveAttribute('aria-valuenow', '500')
  })
})
