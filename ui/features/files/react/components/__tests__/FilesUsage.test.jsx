/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import $ from 'jquery'
import FilesUsage from '../FilesUsage'

describe('FilesUsage', () => {
  let props
  let mockGet

  beforeEach(() => {
    props = {
      contextType: 'users',
      contextId: 4,
    }

    mockGet = jest.spyOn($, 'get')
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('requests quota information from the correct API endpoint', async () => {
    mockGet.mockImplementation(() => ({
      done: () => ({fail: () => {}}),
    }))

    render(<FilesUsage {...props} />)
    expect(mockGet.mock.calls[0][0]).toBe('/api/v1/users/4/files/quota')
  })

  it('displays correct quota usage information when data is loaded', async () => {
    const quotaData = {
      quota: 1024 * 1024 * 100, // 100MB
      quota_used: 1024 * 1024 * 25, // 25MB
    }

    mockGet.mockImplementation((url, callback) => {
      if (callback) callback(quotaData)
      return {
        done: cb => {
          cb(quotaData)
          return {fail: () => {}}
        },
        fail: () => {},
      }
    })

    const {getByTestId} = render(<FilesUsage {...props} />)

    await waitFor(() => {
      // Verify progress bar width is correctly calculated
      const progressBar = getByTestId('progress-bar')
      expect(progressBar).toHaveStyle({width: '25%'})

      // Verify usage text shows correct percentage and formatted size
      const usageText = getByTestId('usage-text')
      expect(usageText).toHaveTextContent('25% of 104.9 MB used')

      // Verify screenreader text includes full context
      const srText = getByTestId('sr-usage-text')
      expect(srText).toHaveTextContent('Files Quota: 25% of 104.9 MB used')
    })
  })

  it('shows empty state when quota data is not yet loaded', () => {
    mockGet.mockImplementation(() => ({
      done: () => ({fail: () => {}}),
    }))

    const {container} = render(<FilesUsage {...props} />)
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('handles API errors gracefully', async () => {
    mockGet.mockImplementation(() => ({
      done: () => ({
        fail: cb => {
          cb({status: 500})
          return {}
        },
      }),
    }))

    const {container} = render(<FilesUsage {...props} />)
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('fetches quota data immediately on mount', () => {
    mockGet.mockImplementation(() => ({
      done: () => ({fail: () => {}}),
    }))

    render(<FilesUsage {...props} />)
    expect(mockGet).toHaveBeenCalledTimes(1)
  })

  it('formats large quota values correctly', async () => {
    const quotaData = {
      quota: 1024 * 1024 * 1024 * 2, // 2GB
      quota_used: 1024 * 1024 * 512, // 512MB
    }

    mockGet.mockImplementation((url, callback) => {
      if (callback) callback(quotaData)
      return {
        done: cb => {
          cb(quotaData)
          return {fail: () => {}}
        },
        fail: () => {},
      }
    })

    const {getByTestId} = render(<FilesUsage {...props} />)

    await waitFor(() => {
      const progressBar = getByTestId('progress-bar')
      expect(progressBar).toHaveStyle({width: '25%'})

      const usageText = getByTestId('usage-text')
      expect(usageText).toHaveTextContent('25% of 2.1 GB used')
    })
  })
})
