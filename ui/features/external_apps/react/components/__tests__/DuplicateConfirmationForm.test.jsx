/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import DuplicateConfirmationForm from '../DuplicateConfirmationForm'

describe('DuplicateConfirmationForm', () => {
  const defaultProps = {
    onCancel: jest.fn(),
    onSuccess: jest.fn(),
    onError: jest.fn(),
    toolData: {},
    configurationType: '',
    store: {},
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the duplicate confirmation form', () => {
    const {getByTestId} = render(<DuplicateConfirmationForm {...defaultProps} />)
    expect(getByTestId('duplicate-confirmation-form')).toBeInTheDocument()
    expect(getByTestId('confirmation-message')).toHaveTextContent(
      'This tool has already been installed in this context',
    )
  })

  it('calls onCancel when cancel button is clicked', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<DuplicateConfirmationForm {...defaultProps} />)

    await user.click(getByTestId('cancel-install-button'))
    expect(defaultProps.onCancel).toHaveBeenCalledTimes(1)
  })

  it('calls store.save when install button is clicked', async () => {
    const user = userEvent.setup()
    const saveMock = jest.fn()
    const props = {
      ...defaultProps,
      store: {save: saveMock},
    }

    const {getByTestId} = render(<DuplicateConfirmationForm {...props} />)
    await user.click(getByTestId('continue-install-button'))

    expect(saveMock).toHaveBeenCalledTimes(1)
  })

  it('calls forceSaveTool when install button is clicked if provided', async () => {
    const user = userEvent.setup()
    const forceSaveTool = jest.fn()
    const props = {
      ...defaultProps,
      forceSaveTool,
    }

    const {getByTestId} = render(<DuplicateConfirmationForm {...props} />)
    await user.click(getByTestId('continue-install-button'))

    expect(forceSaveTool).toHaveBeenCalledTimes(1)
  })

  it('sets verifyUniqueness to undefined when doing a force install', async () => {
    const user = userEvent.setup()
    const saveMock = jest.fn()
    const props = {
      ...defaultProps,
      store: {save: saveMock},
    }

    const {getByTestId} = render(<DuplicateConfirmationForm {...props} />)
    await user.click(getByTestId('continue-install-button'))

    const calls = saveMock.mock.calls[0]
    expect(calls[1]).toEqual(
      expect.objectContaining({
        verifyUniqueness: undefined,
      }),
    )
  })
})
