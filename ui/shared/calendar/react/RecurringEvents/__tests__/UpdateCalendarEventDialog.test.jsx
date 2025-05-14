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
import {act} from 'react-dom/test-utils'
import {render} from '@testing-library/react'
import {
  UpdateCalendarEventDialog,
  renderUpdateCalendarEventDialog,
} from '../UpdateCalendarEventDialog'

// Mock handlers for testing
const handleCancel = jest.fn()
const handleUpdate = jest.fn()

// Mock event for testing
const eventMock = {
  url: 'http://localhost',
  series_head: false,
}

// Create a unique container ID for each test to avoid conflicts
let containerCounter = 0

function renderDialog(props = {}) {
  // Create a unique container ID
  const containerId = `update_modal_container_${containerCounter++}`

  const container = document.createElement('div')
  container.id = containerId
  document.body.appendChild(container)

  const result = render(
    <UpdateCalendarEventDialog
      isOpen={true}
      event={{
        url: 'http://localhost',
        series_head: false,
      }}
      onCancel={handleCancel}
      onUpdate={handleUpdate}
      {...props}
    />,
    {container},
  )

  // Return the container ID so we can find elements within this specific container
  return {...result, containerId}
}

describe('UpdateCalendarEventDialog', () => {
  beforeEach(() => {
    // Reset mocks before each test
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
  })

  it('renders event series dialog', () => {
    renderDialog()

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector('[aria-label="Confirm Changes"]')
    expect(dialog).not.toBeNull()

    // Find the modal heading within this dialog
    const heading = dialog.querySelector('h2')
    expect(heading).toHaveTextContent('Confirm Changes')

    // Get all radio inputs within this dialog
    const radioInputs = dialog.querySelectorAll('input[type="radio"]')
    expect(radioInputs).toHaveLength(3)

    // Check labels by finding them near the radio inputs
    const labels = dialog.querySelectorAll('.css-ov2i6o-radioInput__label')
    const labelTexts = Array.from(labels).map(label => label.textContent)

    expect(labelTexts).toContain('This event')
    expect(labelTexts).toContain('All events')
    expect(labelTexts).toContain('This and all following events')
  })

  it('renders event series dialog except "following" option for a head event', () => {
    // Create a unique container ID
    const containerId = `update_modal_container_${containerCounter++}`

    const container = document.createElement('div')
    container.id = containerId
    document.body.appendChild(container)

    // Render directly with the series_head property set to true
    render(
      <UpdateCalendarEventDialog
        isOpen={true}
        event={{
          url: 'http://localhost',
          series_head: true,
        }}
        onCancel={handleCancel}
        onUpdate={handleUpdate}
      />,
      {container},
    )

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector('[aria-label="Confirm Changes"]')
    expect(dialog).not.toBeNull()

    // Find the modal heading within this dialog
    const heading = dialog.querySelector('h2')
    expect(heading).toHaveTextContent('Confirm Changes')

    // Get all radio inputs within this dialog
    const radioInputs = dialog.querySelectorAll('input[type="radio"]')
    expect(radioInputs).toHaveLength(2)

    // Check labels by finding them near the radio inputs
    const labels = dialog.querySelectorAll('.css-ov2i6o-radioInput__label')
    const labelTexts = Array.from(labels).map(label => label.textContent)

    expect(labelTexts).toContain('This event')
    expect(labelTexts).toContain('All events')
    expect(labelTexts).not.toContain('This and all following events')
  })

  it('closes on cancel', () => {
    renderDialog()

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector('[aria-label="Confirm Changes"]')
    expect(dialog).not.toBeNull()

    // Get the close button in the modal header (X button)
    const closeButton = dialog.querySelector('[data-instui-modal-close-button="true"] button')
    expect(closeButton).not.toBeNull()

    act(() => {
      closeButton.click()
    })

    expect(handleCancel).toHaveBeenCalled()
  })

  it('calls callbacks with selected option', () => {
    renderDialog()

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector('[aria-label="Confirm Changes"]')
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
    const confirmButton = dialog.querySelector('.css-1a66jsg-modalFooter button:last-child')
    expect(confirmButton).not.toBeNull()

    // Click the confirm button
    act(() => {
      confirmButton.click()
    })

    expect(handleUpdate).toHaveBeenCalledWith('all')
  })

  describe('render function', () => {
    it('renders', () => {
      // Create a unique container for this test
      const containerId = 'update_modal_container_test'
      const existingContainer = document.getElementById(containerId)
      if (existingContainer) {
        document.body.removeChild(existingContainer)
      }

      const container = document.createElement('div')
      container.id = containerId
      document.body.appendChild(container)

      renderUpdateCalendarEventDialog(eventMock)
      const dialog = document.querySelector('[role="dialog"]')
      expect(dialog).not.toBeNull()

      // Clean up
      if (container.parentNode) {
        document.body.removeChild(container)
      }
    })
  })
})
