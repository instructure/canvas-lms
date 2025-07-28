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
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import ConfirmationForm from '../ConfirmationForm'

function newProps(overrides) {
  return {
    onCancel: jest.fn(),
    onConfirm: jest.fn(),
    message: 'Are you sure you want to install the tool?',
    confirmLabel: 'Yes, please',
    cancelLabel: 'Nope!',
    ...overrides,
  }
}

function mountSubject(props = newProps()) {
  return {
    user: userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never}),
    ...render(<ConfirmationForm {...props} />),
  }
}

it('uses the specified cancelLabel', async () => {
  const {findByText} = mountSubject()
  const button = await findByText('Nope!', {exact: false})
  expect(button).toBeInTheDocument()
})

it('uses the specified confirmLabel', async () => {
  const {findByText} = mountSubject()
  const button = await findByText('Yes, please', {exact: false})
  expect(button).toBeInTheDocument()
})

it('uses the specified message', async () => {
  const props = newProps()
  const {findByText} = mountSubject(props)
  const text = await findByText(props.message)
  expect(text).toBeInTheDocument()
})

it('calls "onCancel" when cancel button is clicked', async () => {
  const props = newProps()
  const {user, findByText, unmount} = mountSubject(props)
  const button = await findByText('Nope!', {exact: false})
  await user.click(button)
  expect(props.onCancel).toHaveBeenCalled()
  unmount()
}, 5000)

it('calls "onConfirm" when confirm button is clicked', async () => {
  const props = newProps()
  const {user, findByText} = mountSubject(props)
  const button = await findByText('Yes, please')
  await user.click(button)
  expect(props.onConfirm).toHaveBeenCalled()
})
