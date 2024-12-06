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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ConfirmationModal} from '../ConfirmationModal'

describe('ConfirmationModal', () => {
  const onSubmit = jest.fn()
  const onClose = jest.fn()

  const renderConfirmationModal = () => {
    return render(<ConfirmationModal isOpen={true} onSubmit={onSubmit} onRequestClose={onClose} />)
  }

  afterEach(() => {
    onSubmit.mockClear()
    onClose.mockClear()
  })

  it('does not submit form', async () => {
    const {getByText} = renderConfirmationModal()

    await userEvent.click(getByText('Cancel').closest('button'))

    expect(onSubmit).toHaveBeenCalledTimes(0)
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('will submit form', async () => {
    const {getByText} = renderConfirmationModal()

    await userEvent.click(getByText('Confirm').closest('button'))

    expect(onSubmit).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledTimes(0)
  })
})
