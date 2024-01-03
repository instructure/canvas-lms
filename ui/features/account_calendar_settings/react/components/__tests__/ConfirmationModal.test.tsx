/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ConfirmationModal, {type ComponentProps} from '../ConfirmationModal'

const defaultProps: ComponentProps = {
  isOpen: true,
  onCancel: jest.fn(),
  onConfirm: jest.fn(),
}

describe('ConfirmationModal', () => {
  it('renders the confirmation modal', () => {
    const {getByRole} = render(<ConfirmationModal {...defaultProps} />)
    const modalTitle = getByRole('heading', {name: 'Apply Changes'})
    expect(modalTitle).toBeInTheDocument()
  })

  it('calls onConfirm when Confirm button is pressed', () => {
    const onConfirm = jest.fn()
    const {getByRole} = render(<ConfirmationModal {...defaultProps} onConfirm={onConfirm} />)
    getByRole('button', {name: 'Confirm'}).click()
    expect(onConfirm).toHaveBeenCalledTimes(1)
  })

  it('calls onCancel when Cancel button is pressed', () => {
    const onCancel = jest.fn()
    const {getByRole} = render(<ConfirmationModal {...defaultProps} onCancel={onCancel} />)
    getByRole('button', {name: 'Cancel'}).click()
    expect(onCancel).toHaveBeenCalledTimes(1)
  })
})
