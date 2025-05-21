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
import {render, screen, waitFor} from '@testing-library/react'

import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import FilesUsageBar from '../FilesUsageBar'
import {FileManagementProvider} from '../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../__tests__/createMockContext'
import {useGetQuota} from '../../hooks/useGetQuota'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn().mockReturnValue(jest.fn()),
}))

jest.mock('../../hooks/useGetQuota', () => ({
  useGetQuota: jest.fn(),
}))

describe('FilesUsageBar', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  const renderComponent = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retryDelay: 1,
          retry: 0,
        },
      },
    })

    return render(
      <MockedQueryClientProvider client={queryClient}>
        <FileManagementProvider value={createMockFileManagementContext()}>
          <FilesUsageBar />
        </FileManagementProvider>
      </MockedQueryClientProvider>,
    )
  }

  it('renders progress bar with quota data when fetch is successful', async () => {
    ;(useGetQuota as jest.Mock).mockImplementation(() => ({
      data: {quota_used: 500_000, quota: 1_000_000},
      error: null,
      isLoading: false,
    }))

    renderComponent()
    const usageText = await screen.findByText(`500 KB of 1 MB used`)
    expect(usageText).toBeInTheDocument()

    const progressBar = document.querySelector(
      'progress[aria-valuetext="File Storage Quota Used 500 KB of 1 MB used"]',
    )
    expect(progressBar).toBeInTheDocument()
  })

  it('displays error message if quota fetch fails', async () => {
    ;(useGetQuota as jest.Mock).mockImplementation(() => ({
      data: null,
      error: new Error('Failed to fetch quota'),
      isLoading: false,
    }))

    renderComponent()
    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith(
        'An error occurred while loading files usage data.',
      )
    })
  })
})
