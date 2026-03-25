/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {vi} from 'vitest'
import {AutoCaptioning} from '../AutoCaptioning'

const LIVE_REGION_ID = 'flash_screenreader_holder'

const mockLanguages = [
  {id: 'en', label: 'English'},
  {id: 'es', label: 'Spanish'},
  {id: 'fr', label: 'French'},
]

type AutoCaptioningProps = Parameters<typeof AutoCaptioning>[0]

function renderComponent(props: Partial<AutoCaptioningProps> = {}) {
  const liveRegion = document.getElementById(LIVE_REGION_ID)

  const defaultProps: AutoCaptioningProps = {
    onCancel: vi.fn(),
    onPrimary: vi.fn(),
    liveRegion: () => liveRegion,
    languages: mockLanguages,
    ...props,
  }

  return render(<AutoCaptioning {...defaultProps} />)
}

describe('<AutoCaptioning />', () => {
  beforeEach(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = LIVE_REGION_ID
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  afterEach(() => {
    const liveRegion = document.getElementById(LIVE_REGION_ID)
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
  })

  it('renders language dropdown with provided languages', () => {
    renderComponent()

    // Open the dropdown by clicking placeholder
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)

    // Verify all languages are present
    expect(screen.getByText('English')).toBeInTheDocument()
    expect(screen.getByText('Spanish')).toBeInTheDocument()
    expect(screen.getByText('French')).toBeInTheDocument()
  })

  it('shows validation error when no language selected', () => {
    renderComponent()

    // Click Request without selecting language
    const requestButton = screen.getByText('Request')
    fireEvent.click(requestButton)

    // Verify error message appears (multiple instances: FormField + Alert)
    const errorMessages = screen.getAllByText('Please select a language')
    expect(errorMessages.length).toBeGreaterThan(0)
  })

  it('clears validation error when language is selected', () => {
    renderComponent()

    // Trigger validation error
    const requestButton = screen.getByText('Request')
    fireEvent.click(requestButton)

    const errorMessages = screen.getAllByText('Please select a language')
    expect(errorMessages.length).toBeGreaterThan(0)

    // Select a language
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    // Verify error disappears
    expect(screen.queryByText('Please select a language')).not.toBeInTheDocument()
  })

  it('calls onPrimary with selected language ID', () => {
    const onPrimary = vi.fn()
    renderComponent({onPrimary})

    // Open dropdown and select English
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    // Click Request
    const requestButton = screen.getByText('Request')
    fireEvent.click(requestButton)

    // Verify onPrimary called with 'en'
    expect(onPrimary).toHaveBeenCalledWith('en')
    expect(onPrimary).toHaveBeenCalledTimes(1)
  })

  it('calls onCancel when Cancel button clicked', () => {
    const onCancel = vi.fn()
    renderComponent({onCancel})

    const cancelButton = screen.getByText('Cancel')
    fireEvent.click(cancelButton)

    expect(onCancel).toHaveBeenCalledTimes(1)
  })

  it('renders with empty language list', () => {
    renderComponent({languages: []})

    expect(screen.getByText('Select Language')).toBeInTheDocument()
    expect(screen.getByText('Language Spoken in This Media*')).toBeInTheDocument()

    // Should still render but with empty dropdown
    expect(screen.getByText('Select Language')).toBeInTheDocument()
    expect(screen.getByText('Cancel')).toBeInTheDocument()
    expect(screen.getByText('Request')).toBeInTheDocument()
  })

  describe('Pendo tracking', () => {
    const mockTrack = vi.fn()

    beforeEach(() => {
      ;(window as any).canvasUsageMetrics = {track: mockTrack}
    })

    afterEach(() => {
      delete (window as any).canvasUsageMetrics
    })

    it('fires canvas_caption_validation_error missing_language when Request clicked with no language', async () => {
      renderComponent()
      fireEvent.click(screen.getByText('Request'))
      await waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('canvas_caption_validation_error', {
          type: 'track',
          flow_type: 'request_auto',
          error_type: 'missing_language',
        })
      })
    })
  })

  describe('.onDirtyStateChanged', () => {
    describe('called with true', () => {
      it('when language is selected', async () => {
        const onDirtyStateChanged = vi.fn()
        renderComponent({onDirtyStateChanged})

        // Select a language - click on placeholder text to open, then click option
        const selectPlaceholder = screen.getByText('Select Language')
        fireEvent.click(selectPlaceholder)
        fireEvent.click(screen.getByText('English'))

        await waitFor(() => {
          expect(onDirtyStateChanged).toHaveBeenCalledWith(true)
        })
      })
    })
  })
})
