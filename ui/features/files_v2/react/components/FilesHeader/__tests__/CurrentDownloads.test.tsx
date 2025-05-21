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
import {render, screen, waitFor, act} from '@testing-library/react'
import CurrentDownloads from '../CurrentDownloads'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {performRequest} from '../../../../utils/downloadUtils'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(() => jest.fn()),
}))

jest.mock('jquery', () => {
  const mockFlashError = jest.fn()
  const jqueryMock = jest.fn() as jest.Mock & {flashError: jest.Mock}
  jqueryMock.flashError = mockFlashError
  return jqueryMock
})

jest.mock('../../../../utils/downloadUtils', () => ({
  addDownloadListener: jest.fn(fn => window.addEventListener('download_utils_event', fn)),
  removeDownloadListener: jest.fn(fn => window.removeEventListener('download_utils_event', fn)),
  performRequest: jest.fn(),
  downloadFile: jest.fn(),
}))

const renderComponent = () => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <CurrentDownloads rows={[]} />
    </FileManagementProvider>,
  )
}

describe('CurrentDownloads', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders null when not downloading', () => {
    renderComponent()
    expect(screen.queryByTestId('current-downloads')).toBeNull()
  })

  it('does not render when downloading just one file', async () => {
    renderComponent()
    ;(performRequest as jest.Mock).mockReturnValue(false)

    act(() => {
      window.dispatchEvent(
        new CustomEvent('download_utils_event', {detail: {items: new Set(['file'])}}),
      )
    })

    await waitFor(() => {
      expect(performRequest).toHaveBeenCalledTimes(1)
      expect(screen.queryByTestId('current-downloads')).toBeNull()
    })
  })

  it('shows flash error if download already in progress', async () => {
    renderComponent()
    ;(performRequest as jest.Mock).mockReturnValue(true)

    act(() => {
      window.dispatchEvent(
        new CustomEvent('download_utils_event', {detail: {items: new Set(['1'])}}),
      )
    })

    await waitFor(() => {
      expect(screen.getByTestId('current-downloads')).toBeInTheDocument()
    })

    act(() => {
      window.dispatchEvent(
        new CustomEvent('download_utils_event', {detail: {items: new Set(['2', 'file2'])}}),
      )
    })

    expect(showFlashError).toHaveBeenCalledWith('Download already in progress.')
  })

  it('calls performRequest with correct parameters', async () => {
    renderComponent()
    ;(performRequest as jest.Mock).mockReturnValue(true)

    act(() => {
      window.dispatchEvent(
        new CustomEvent('download_utils_event', {detail: {items: new Set(['1'])}}),
      )
    })

    await waitFor(() => {
      expect(performRequest).toHaveBeenCalledWith({
        contextType: 'courses',
        contextId: '2',
        items: new Set(['1']),
        rows: [],
        onProgress: expect.any(Function),
        onComplete: expect.any(Function),
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('current-downloads')).toBeInTheDocument()
      expect(screen.getAllByText(/Preparing download: 0% complete/)).toHaveLength(2)
    })
  })
})
