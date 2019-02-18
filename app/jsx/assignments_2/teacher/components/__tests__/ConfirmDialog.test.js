/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from 'react-testing-library'

import ConfirmDialog from '../ConfirmDialog'

function renderConfirmDialog(overrideProps = {}) {
  const props = {
    open: true,
    working: false,
    heading: 'the thing',
    message: 'do you want to do the thing?',
    confirmLabel: 'do the thing',
    cancelLabel: 'refrain from doing the thing',
    closeLabel: 'close the dialog',
    spinnerLabel: 'doing the thing',
    ...overrideProps
  }
  return render(<ConfirmDialog {...props} />)
}

it('triggers close', () => {
  const onClose = jest.fn()
  const {getByTestId} = renderConfirmDialog({onClose})
  fireEvent.click(getByTestId('confirm-dialog-close-button'))
  expect(onClose).toHaveBeenCalled()
})

it('triggers cancel', () => {
  const onCancel = jest.fn()
  const {getByTestId} = renderConfirmDialog({onCancel})
  fireEvent.click(getByTestId('confirm-dialog-cancel-button'))
  expect(onCancel).toHaveBeenCalled()
})

it('triggers confirm', () => {
  const onConfirm = jest.fn()
  const {getByTestId} = renderConfirmDialog({onConfirm})
  fireEvent.click(getByTestId('confirm-dialog-confirm-button'))
  expect(onConfirm).toHaveBeenCalled()
})

it('shows the spinner and disabled buttons when working', () => {
  const {getByText, getByTestId} = renderConfirmDialog({working: true})
  expect(getByText('doing the thing')).toBeInTheDocument()
  expect(getByTestId('confirm-dialog-close-button').getAttribute('disabled')).toBe('')
  expect(getByTestId('confirm-dialog-cancel-button').getAttribute('disabled')).toBe('')
  expect(getByTestId('confirm-dialog-confirm-button').getAttribute('disabled')).toBe('')
})
