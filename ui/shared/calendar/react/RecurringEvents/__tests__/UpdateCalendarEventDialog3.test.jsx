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
import {render, act} from '@testing-library/react'

import {UpdateCalendarEventDialog} from '../UpdateCalendarEventDialog'

const eventMock = {
  url: 'http://localhost',
  series_head: false,
}

const handleCancel = jest.fn()
const handleUpdate = jest.fn()

const defaultProps = {
  event: eventMock,
  isOpen: true,
  onCancel: handleCancel,
  onUpdate: handleUpdate,
}

function renderDialog(overrideProps = {}) {
  const props = {...defaultProps, ...overrideProps}
  return render(<UpdateCalendarEventDialog {...props} />)
}

describe('UpdateCalendarEventDialog', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(() => {
    // Clean up all test containers
    const containers = document.querySelectorAll('[id^="update_modal_container_"]')
    containers.forEach(container => {
      if (container && container.parentNode) {
        container.parentNode.removeChild(container)
      }
    })

    // Reset mocks
    jest.clearAllMocks()
  })

  it('calls callbacks with selected option', () => {
    const {containerId} = renderDialog()

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector(`[aria-label="Confirm Changes"]`)
    expect(dialog).not.toBeNull()

    // Find all radio inputs within this dialog
    const radioInputs = dialog.querySelectorAll('input[type="radio"]')

    // Find the 'all' radio input (second one)
    const allEventsRadio = radioInputs[1]

    // Click the radio button to select it
    act(() => {
      allEventsRadio.click()
    })

    // Find the confirm button in the footer
    const confirmButton = dialog.querySelector('.css-1q7wie3-modalFooter button:last-child')
    expect(confirmButton).not.toBeNull()

    // Click the confirm button
    act(() => {
      confirmButton.click()
    })

    expect(handleUpdate).toHaveBeenCalledWith('all')
  })
})
