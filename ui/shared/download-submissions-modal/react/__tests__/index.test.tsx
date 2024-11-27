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
import {render, waitFor} from '@testing-library/react'
import DownloadSubmissionModal from '../index'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

const setUp = (propOverrides = {}) => {
  const props = {
    open: true,
    handleCloseModal: () => {},
    assignmentId: '1',
    courseId: '1',
    breakpoints: {},
    ...propOverrides,
  }
  // @ts-expect-error
  return render(<DownloadSubmissionModal {...props} />)
}

beforeEach(() => {
  // @ts-expect-error
  doFetchApi.mockResolvedValue({
    json: {
      attachment: {
        size: 100,
      },
    },
  })
})

afterEach(() => {
  // @ts-expect-error
  doFetchApi.mockClear()
})

describe('DownloadSubmissionModal', () => {
  it('renders 1% progress and in-progress text when the modal opens and initiates download', () => {
    const {getByTestId} = setUp()
    expect(getByTestId('progress-value').textContent).toBe('1%')
    expect(getByTestId('progress-text').textContent).toBe('In Progress.')
  })

  it('renders 100% progress and success text when the download is complete', async () => {
    const {getByTestId} = setUp()
    await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(1))
    expect(await getByTestId('progress-value').textContent).toBe('100%')
    expect(getByTestId('progress-text').textContent).toBe('Finished preparing 100 Bytes.')
  })

  it('enables the download button when download is complete', async () => {
    const {getByTestId} = setUp()
    await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(1))
    const button = getByTestId('download_button')
    expect(button).not.toHaveAttribute('disabled')
  })

  describe('error while downloading', () => {
    beforeEach(() => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue(new Error('error'))
    })

    afterEach(() => {
      // @ts-expect-error
      doFetchApi.mockClear()
    })

    it('renders error text', async () => {
      const {getByTestId} = setUp()
      await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(1))
      expect(getByTestId('progress-text').textContent).toBe('Failed to gather and compress files.')
    })

    it('does not enable the download button', async () => {
      const {getByTestId} = setUp()
      await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(1))
      const button = getByTestId('download_button')
      expect(button).toHaveAttribute('disabled')
    })
  })
})
