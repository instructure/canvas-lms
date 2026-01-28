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

import {
  UpdateCalendarEventDialog,
  renderUpdateCalendarEventDialog,
} from '../UpdateCalendarEventDialog'

const eventMock = {
  url: 'http://localhost',
  series_head: false,
}

const handleCancel = vi.fn()
const handleUpdate = vi.fn()

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
    vi.clearAllMocks()
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
    vi.clearAllMocks()
  })

  it('renders event series dialog', () => {
    renderDialog()

    // Find the dialog that was rendered for this specific test
    const dialog = document.querySelector(`[aria-label="Confirm Changes"]`)
    expect(dialog).not.toBeNull()

    // Find the modal heading within this dialog
    const heading = dialog.querySelector('h2')
    expect(heading).toHaveTextContent('Confirm Changes')

    // Get all radio inputs within this dialog
    const radioInputs = dialog.querySelectorAll('input[type="radio"]')
    expect(radioInputs).toHaveLength(3)

    // Check labels by finding the label text associated with each radio input
    const radioLabels = Array.from(radioInputs).map(radio => {
      // Find the label by the aria-describedby or id reference
      const labelId = radio.getAttribute('aria-describedby')
      if (labelId) {
        const labelElement = dialog.querySelector(`#${labelId}`)
        if (labelElement) return labelElement.textContent
      }
      // Fallback: find label element that wraps the input or is connected via for attribute
      const labelElement =
        radio.closest('label') || dialog.querySelector(`label[for="${radio.id}"]`)
      return labelElement?.textContent || ''
    })

    // Use getByRole to find the actual label text content more reliably
    const dialogText = dialog.textContent
    expect(dialogText).toContain('This event')
    expect(dialogText).toContain('All events')
    expect(dialogText).toContain('This and all following events')
  })

  describe('render function', () => {
    it('renders', async () => {
      const container = document.createElement('div')
      container.id = 'update_modal_container'
      document.body.appendChild(container)

      renderUpdateCalendarEventDialog(eventMock)
      // Wait for React 18 concurrent rendering to complete
      await vi.waitFor(() => {
        const dialog = document.querySelector('[role="dialog"]')
        expect(dialog).toBeInTheDocument()
      })

      document.body.removeChild(container)
    })
  })
})
