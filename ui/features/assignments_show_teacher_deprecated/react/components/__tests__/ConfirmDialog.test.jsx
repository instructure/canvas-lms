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
import {render, fireEvent} from '@testing-library/react'
import '../../test-utils'

import ConfirmDialog from '../ConfirmDialog'

function renderConfirmDialog(overrideProps = {}) {
  const props = {
    open: true,
    working: false,
    disabled: false,
    heading: 'the thing',
    body: () => 'do you want to do the thing?',
    buttons: () => [{children: 'a button', 'data-testid': 'the-button'}],
    closeLabel: 'close the dialog',
    spinnerLabel: 'doing the thing',
    ...overrideProps,
  }
  return render(<ConfirmDialog {...props} />)
}

it('renders the body', () => {
  const {getByText} = renderConfirmDialog()
  expect(getByText('do you want to do the thing?')).toBeInTheDocument()
})

it('triggers close', () => {
  const onDismiss = jest.fn()
  const {getByText} = renderConfirmDialog({onDismiss})
  fireEvent.click(getByText('close the dialog'))
  expect(onDismiss).toHaveBeenCalled()
})

it('creates buttons and passes through button properties', () => {
  const clicked = jest.fn()
  const {getByTestId} = renderConfirmDialog({
    buttons: () => [
      {children: 'click me', onClick: clicked, 'data-testid': 'test-button'},
      {children: 'other button', disabled: true, 'data-testid': 'disabled-button'},
    ],
  })
  fireEvent.click(getByTestId('test-button'))
  expect(clicked).toHaveBeenCalled()
  expect(getByTestId('disabled-button').getAttribute('disabled')).toBe('')
})

it('shows the spinner with enabled buttons when working', () => {
  const {getByText, getByTestId} = renderConfirmDialog({working: true})
  expect(getByText('doing the thing')).toBeInTheDocument()
  expect(getByTestId('confirm-dialog-close-button').getAttribute('disabled')).toBe(null)
  expect(getByTestId('the-button').getAttribute('disabled')).toBe(null)
})

it('shows custom mask body', () => {
  const {getByText} = renderConfirmDialog({busyMaskBody: () => 'I am busy', working: true})
  expect(getByText('I am busy')).toBeInTheDocument()
})

it('shows disabled buttons when disabled', () => {
  const {getByText, getByTestId} = renderConfirmDialog({disabled: true})
  expect(() => getByText('doing the thing')).toThrow()
  expect(getByTestId('confirm-dialog-close-button').getAttribute('disabled')).toBe('')
  expect(getByTestId('the-button').getAttribute('disabled')).toBe('')
})
