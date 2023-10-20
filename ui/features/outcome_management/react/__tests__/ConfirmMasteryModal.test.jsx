/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ConfirmMasteryModal from '../ConfirmMasteryModal'
import {render, fireEvent} from '@testing-library/react'

const defaultProps = () => ({
  onConfirm: () => {},
  isOpen: true,
  onClose: () => {},
  title: 'title',
  modalText: 'body!!',
})

it('calls onClose and does not call onConfirm when canceled', () => {
  const onConfirm = jest.fn()
  const onClose = jest.fn()
  const {getByText} = render(
    <ConfirmMasteryModal {...defaultProps()} onConfirm={onConfirm} onClose={onClose} />
  )
  fireEvent.click(getByText('Cancel'))
  expect(onConfirm).not.toHaveBeenCalled()
  expect(onClose).toHaveBeenCalled()
})

it('does call onConfirm when saved', () => {
  const onConfirm = jest.fn()
  const {getByText} = render(<ConfirmMasteryModal {...defaultProps()} onConfirm={onConfirm} />)
  fireEvent.click(getByText('Save'))
  expect(onConfirm).toHaveBeenCalled()
})

it('renders the modalText, title and confirmButton provided as props', () => {
  const {getByText} = render(
    <ConfirmMasteryModal {...defaultProps()} confirmButtonText="Confirm" />
  )
  expect(getByText(/title/)).not.toBeNull()
  expect(getByText(/body!!/)).not.toBeNull()
  expect(getByText(/Confirm/)).not.toBeNull()
})
