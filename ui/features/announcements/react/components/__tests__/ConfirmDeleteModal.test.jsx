/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import merge from 'lodash/merge'
import ConfirmDeleteModal from '../ConfirmDeleteModal'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const makeProps = (props = {}) =>
  merge(
    {
      onConfirm() {},
      onCancel() {},
      onHide() {},
      modalRef() {},
      selectedCount: 1,
      applicationElement: () => document.getElementById('fixtures'),
    },
    props,
  )

describe('ConfirmDeleteModal component', () => {
  let modal

  beforeEach(() => {
    modal = null
  })

  afterEach(() => {
    if (modal) {
      modal.hide()
    }
  })

  test('should call onConfirm prop after confirming delete', async () => {
    const user = userEvent.setup()
    const confirmSpy = jest.fn()
    const modalRef = jest.fn(ref => {
      modal = ref
    })

    const {getByTestId} = render(
      <ConfirmDeleteModal {...makeProps({onConfirm: confirmSpy, modalRef})} />,
    )

    // Show the modal
    modal.show()

    const confirmButton = getByTestId('confirm-delete-announcements')
    await user.click(confirmButton)

    // Wait for setTimeout in component
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(confirmSpy).toHaveBeenCalledTimes(1)
  })

  test('should call onHide prop after confirming delete', async () => {
    const user = userEvent.setup()
    const hideSpy = jest.fn()
    const modalRef = jest.fn(ref => {
      modal = ref
    })

    const {getByTestId} = render(<ConfirmDeleteModal {...makeProps({onHide: hideSpy, modalRef})} />)

    // Show the modal
    modal.show()

    const confirmButton = getByTestId('confirm-delete-announcements')
    await user.click(confirmButton)

    // Wait for setTimeout in component
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(hideSpy).toHaveBeenCalledTimes(1)
  })

  test('should call onCancel prop after cancelling', async () => {
    const user = userEvent.setup()
    const cancelSpy = jest.fn()
    const modalRef = jest.fn(ref => {
      modal = ref
    })

    const {getByTestId} = render(
      <ConfirmDeleteModal {...makeProps({onCancel: cancelSpy, modalRef})} />,
    )

    // Show the modal
    modal.show()

    const cancelButton = getByTestId('cancel-delete-announcements')
    await user.click(cancelButton)

    // Wait for setTimeout in component
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(cancelSpy).toHaveBeenCalledTimes(1)
  })

  test('should call onHide prop after cancelling', async () => {
    const user = userEvent.setup()
    const hideSpy = jest.fn()
    const modalRef = jest.fn(ref => {
      modal = ref
    })

    const {getByTestId} = render(<ConfirmDeleteModal {...makeProps({onHide: hideSpy, modalRef})} />)

    // Show the modal
    modal.show()

    const cancelButton = getByTestId('cancel-delete-announcements')
    await user.click(cancelButton)

    // Wait for setTimeout in component
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(hideSpy).toHaveBeenCalledTimes(1)
  })
})
