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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {RevertAccount} from '../RevertAccount'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

describe('RevertAccount', () => {
  const setup = (propOverrides = {}) => {
    const props = {
      accountId: '123',
      isHorizonAccountLocked: false,
      ...propOverrides,
    }
    return render(<RevertAccount {...props} />)
  }
  it('makes an API call when the Revert button is clicked', () => {
    ;(doFetchApi as jest.Mock).mockResolvedValue({})

    setup()

    const revertButton = screen
      .getAllByText('Revert Sub Account')
      .find(element => element.tagName === 'SPAN')

    expect(revertButton).not.toBeUndefined()
    fireEvent.click(revertButton!)

    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/accounts/123',
      method: 'PUT',
      body: {
        id: '123',
        account: {settings: {horizon_account: {value: false}}},
      },
    })
  })

  it('shows an error message when API call fails', async () => {
    ;(doFetchApi as jest.Mock).mockRejectedValue({ok: false})

    setup()

    const revertButton = screen
      .getAllByText('Revert Sub Account')
      .find(element => element.tagName === 'SPAN')

    expect(revertButton).not.toBeUndefined()
    fireEvent.click(revertButton!)

    waitFor(() => {
      expect(
        screen.getByText('Failed to revert sub-account. Please try again.'),
      ).toBeInTheDocument()
    })
  })
})
