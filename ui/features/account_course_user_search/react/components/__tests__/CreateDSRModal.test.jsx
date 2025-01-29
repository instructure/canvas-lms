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
import {render, fireEvent, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import CreateDSRModal from '../CreateDSRModal'
import axios from '@canvas/axios'

jest.mock('@canvas/axios')

const mockUser = {
  id: '1',
  name: 'John Doe',
}

const mockAccountId = '123'

const futureDate = () => {
  const date = new Date()
  date.setDate(date.getDate() + 1)
  return date
}

const pastDate = () => {
  const date = new Date()
  date.setDate(date.getDate() - 1)
  return date
}

describe('CreateDSRModal', () => {
  const afterSave = jest.fn()

  const renderComponent = (props = {}) =>
    render(
      <CreateDSRModal accountId={mockAccountId} user={mockUser} afterSave={afterSave} {...props}>
        {}
        <button title="Create DSR Request for John Doe" />
      </CreateDSRModal>,
    )

  it("uses the user's name in the default report name", () => {
    axios.get.mockResolvedValueOnce({status: 204, data: {}})

    const {getByTitle, getByTestId} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    const input = getByTestId('DSR Request Name')
    expect(input.value).toMatch(/John-Doe/)
  })

  it('should not show latest request if there is none', async () => {
    axios.get.mockResolvedValueOnce({status: 204, data: {}})

    const {queryByText, getByTitle} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(queryByText('Latest DSR:')).not.toBeInTheDocument()
    })
  })

  it('should fetch the latest DSR request on modal open', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        request_name: 'Latest Request',
        progress_status: 'completed',
        download_url: 'http://download',
      },
    })

    const {getByText, getByTitle} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(getByText('Latest DSR:')).toBeInTheDocument()
      expect(getByText('Latest Request')).toBeInTheDocument()
    })
  })

  it('should not have a download link and show the status when pending', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        request_name: 'Latest Request',
        progress_status: 'running',
      },
    })

    const {getByText, queryByText, getByTitle} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(
        getByText((_, element) => element.textContent === 'Latest DSR: In progress'),
      ).toBeInTheDocument()
      expect(queryByText('Download:')).not.toBeInTheDocument()
    })
  })

  it('should not have a download link and show the status when failed', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        request_name: 'Latest Request',
        progress_status: 'failed',
      },
    })

    const {getByText, queryByText, getByTitle} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      expect(
        getByText((_, element) => element.textContent === 'Latest DSR: Failed'),
      ).toBeInTheDocument()
      expect(queryByText('Download:')).not.toBeInTheDocument()
    })
  })

  it('blocks creation when the previous report is still running', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        progress_status: 'running',
      },
    })

    const {getByTitle, getByTestId, getByText} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      const submitButton = getByTestId('submit-button')
      expect(submitButton).toBeDisabled()
      const tooltip = getByText('A request is already in progress')
      expect(tooltip).toBeInTheDocument()
    })
  })

  it('blocks creation when the previous report has not expired', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        progress_status: 'completed',
        expires_at: futureDate().toISOString(),
      },
    })

    const {getByTitle, getByTestId, getByText} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      const submitButton = getByTestId('submit-button')
      expect(submitButton).toBeDisabled()
      const tooltip = getByText(/The previous request expires/)
      expect(tooltip).toBeInTheDocument()
    })
  })

  it('does not block creation if the previous report is not running nor expired', async () => {
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: {
        progress_status: 'completed',
        expires_at: pastDate().toISOString(),
      },
    })

    const {getByTitle, getByTestId} = renderComponent()
    fireEvent.click(getByTitle('Create DSR Request for John Doe'))

    await waitFor(() => {
      const submitButton = getByTestId('submit-button')
      expect(submitButton).toBeEnabled()
    })
  })
})
