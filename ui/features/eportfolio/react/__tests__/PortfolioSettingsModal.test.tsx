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
import PortfolioSettingsModal from '../PortfolioSettingsModal'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

// Track API calls
let putCalled = false

describe('PortfolioSettingsModal', () => {
  const portfolio = {
    id: 0,
    name: 'Test Portfolio',
    public: true,
    profile_url: '/path/to/profile',
  }
  const mockConfirm = vi.fn()
  const mockCancel = vi.fn()

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
    putCalled = false
    vi.clearAllMocks()

    server.use(
      http.put('/eportfolios/:portfolioId', () => {
        putCalled = true
        return HttpResponse.json({}, {status: 200})
      }),
    )
  })

  it('renders default values', () => {
    const {getByDisplayValue, getByTestId} = render(
      <PortfolioSettingsModal
        portfolio={portfolio}
        onConfirm={mockConfirm}
        onCancel={mockCancel}
      />,
    )
    const textInput = getByDisplayValue('Test Portfolio')
    expect(textInput).toBeInTheDocument()
    const checkbox = getByTestId('mark-as-public')
    expect(checkbox).toBeChecked()
  })

  it('sets focus and shows error if name is blank', async () => {
    const {getByTestId, getByText} = render(
      <PortfolioSettingsModal
        portfolio={{...portfolio, name: ''}}
        onConfirm={mockConfirm}
        onCancel={mockCancel}
      />,
    )
    const textInput = getByTestId('portfolio-name-field')
    const saveButton = getByText('Save')
    saveButton.click()
    await waitFor(() => {
      expect(textInput).toHaveFocus()
      expect(getByText('Name is required.')).toBeInTheDocument()
    })
  })

  it('updates portfolio after saving', async () => {
    const {getByText} = render(
      <PortfolioSettingsModal
        portfolio={portfolio}
        onConfirm={mockConfirm}
        onCancel={mockCancel}
      />,
    )
    const saveButton = getByText('Save')
    saveButton.click()
    await waitFor(() => expect(putCalled).toBe(true))
    await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
  })

  it('does not update portfolio after cancel', async () => {
    const {getByText} = render(
      <PortfolioSettingsModal
        portfolio={portfolio}
        onConfirm={mockConfirm}
        onCancel={mockCancel}
      />,
    )
    const cancelButton = getByText('Cancel')
    cancelButton.click()
    await waitFor(() => expect(putCalled).toBe(false))
    await waitFor(() => expect(mockCancel).toHaveBeenCalled())
  })
})
