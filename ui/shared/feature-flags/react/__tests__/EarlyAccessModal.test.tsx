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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'

import EarlyAccessModal from '../EarlyAccessModal'

describe('EarlyAccessModal', () => {
  const user = userEvent.setup()

  beforeEach(() => {
    fakeENV.setup({
      CONTEXT_BASE_URL: '/accounts/1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    fetchMock.restore()
  })

  it('calls onAccept after successful API call when accept button is clicked', async () => {
    const onAccept = jest.fn()
    const onCancel = jest.fn()

    fetchMock.postOnce('/api/v1/accounts/1/features/early_access_program', {
      early_access_program: true,
    })

    const {getByText, getByTestId} = render(
      <EarlyAccessModal isOpen={true} onAccept={onAccept} onCancel={onCancel} />,
    )

    expect(getByText('Early Access Program Terms and Conditions')).toBeInTheDocument()

    const acceptButton = getByTestId('eap-accept-button')
    await user.click(acceptButton)

    await waitFor(() => {
      expect(fetchMock.called('/api/v1/accounts/1/features/early_access_program')).toBe(true)
    })

    await waitFor(() => {
      expect(onAccept).toHaveBeenCalled()
    })

    expect(onCancel).not.toHaveBeenCalled()
  })

  it('calls onCancel without API call when cancel button is clicked', async () => {
    const onAccept = jest.fn()
    const onCancel = jest.fn()

    const {getByText, getByTestId} = render(
      <EarlyAccessModal isOpen={true} onAccept={onAccept} onCancel={onCancel} />,
    )

    expect(getByText('Early Access Program Terms and Conditions')).toBeInTheDocument()

    const cancelButton = getByTestId('eap-cancel-button')
    await user.click(cancelButton)

    expect(onCancel).toHaveBeenCalled()
    expect(onAccept).not.toHaveBeenCalled()
    expect(fetchMock.called()).toBe(false)
  })

  it('does not render when isOpen is false', () => {
    const onAccept = jest.fn()
    const onCancel = jest.fn()

    const {queryByText} = render(
      <EarlyAccessModal isOpen={false} onAccept={onAccept} onCancel={onCancel} />,
    )

    expect(queryByText('Early Access Program Terms and Conditions')).not.toBeInTheDocument()
  })
})
