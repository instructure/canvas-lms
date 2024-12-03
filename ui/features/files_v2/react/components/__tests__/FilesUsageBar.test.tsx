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
import fetchMock from 'fetch-mock'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import FilesUsageBar from '../FilesUsageBar'

const FILES_USAGE_RESULT = {
  quota_used: 500,
  quota: 1000,
}

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn().mockReturnValue(jest.fn()),
}))

describe('FilesUsageBar', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    fetchMock.get(/.*\/files\/quota/, FILES_USAGE_RESULT)
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const renderComponent = (props = {}) => {
    const queryClient = new QueryClient({
      logger: {
        log: () => {},
        warn: () => {},
        error: () => {},
      },
      defaultOptions: {
        queries: {
          retryDelay: 1,
          retry: 0,
        },
      },
    })
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <FilesUsageBar contextType="course" contextId="2" {...props} />
      </MockedQueryClientProvider>
    )
  }

  it('renders progress bar with quota data when fetch is successful', async () => {
    renderComponent()
    const quota = '1 KB'
    const percentageText = await screen.findByText(`50% of ${quota} used`)
    expect(percentageText).toBeInTheDocument()

    const progressBar = screen.getByLabelText(/File Storage Quota Used/i)
    expect(progressBar).toBeInTheDocument()
  })

  it('displays error message if quota fetch fails', async () => {
    fetchMock.get(/.*\/files\/quota/, 500, {overwriteRoutes: true})
    renderComponent()
    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith(
        'An error occurred while loading files usage data'
      )
    })
  })
})
