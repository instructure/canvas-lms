/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {ClosedCaptionPanelV2} from '../ClosedCaptionPanelV2'
import type {Subtitle} from '../types'

const LIVE_REGION_ID = 'flash_screenreader_holder'

function createValidFile(name = 'captions.vtt', size = 1000): File {
  const content = new Array(size).fill('a').join('')
  return new File([content], name, {type: 'text/vtt'})
}

function renderComponent(overrideProps = {}) {
  const defaultProps = {
    liveRegion: () => document.getElementById(LIVE_REGION_ID),
    onUpdateSubtitles: vi.fn(),
    subtitles: [],
    userLocale: 'en',
  }

  return {
    ...render(<ClosedCaptionPanelV2 {...defaultProps} {...overrideProps} />),
    props: {...defaultProps, ...overrideProps},
  }
}

describe('<ClosedCaptionPanelV2 />', () => {
  beforeEach(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = LIVE_REGION_ID
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)

    // Mock setTimeout to avoid waiting in tests
    vi.useFakeTimers()
  })

  const ADD_NEW_BUTTON_TEXT = 'Add New'
  const REQUEST_BUTTON_TEXT = 'Request'

  afterEach(() => {
    const liveRegion = document.getElementById(LIVE_REGION_ID)
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
    vi.useRealTimers()
  })

  it('shows add new and request buttons by default', () => {
    renderComponent()

    expect(screen.getByText(ADD_NEW_BUTTON_TEXT)).toBeInTheDocument()
    expect(screen.getByText(REQUEST_BUTTON_TEXT)).toBeInTheDocument()
  })

  it('clicking add new shows manual caption creator', () => {
    renderComponent()

    const addNewButton = screen.getByText(ADD_NEW_BUTTON_TEXT)
    fireEvent.click(addNewButton)

    // Manual caption creator should be visible
    expect(screen.getByText('Select Language')).toBeInTheDocument()
    expect(screen.getByText(/choose file/i)).toBeInTheDocument()
    expect(screen.getByText('Upload')).toBeInTheDocument()
    expect(screen.getByText('Cancel')).toBeInTheDocument()
  })

  it('clicking cancel in manual caption creator hides it and shows the picker again', () => {
    renderComponent()

    // Open manual caption creator
    fireEvent.click(screen.getByText(ADD_NEW_BUTTON_TEXT))

    // Manual creator should be visible
    expect(
      screen.getByText('Upload a subtitle track in either the SRT or WebVTT format.'),
    ).toBeInTheDocument()

    // Click cancel
    const cancelButton = screen.getByText('Cancel')
    fireEvent.click(cancelButton)

    // Should go back to showing picker buttons
    expect(screen.getByText(ADD_NEW_BUTTON_TEXT)).toBeInTheDocument()
    expect(screen.getByText(REQUEST_BUTTON_TEXT)).toBeInTheDocument()
  })

  it('if language and file selected it shows the new language in processing state in the list', () => {
    renderComponent()

    // Open manual caption creator
    const addNewButton = screen.getByText(ADD_NEW_BUTTON_TEXT)
    fireEvent.click(addNewButton)

    // Select a language
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    // Select a file
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    const validFile = createValidFile()
    fireEvent.change(fileInput, {target: {files: [validFile]}})

    // Click Upload
    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // Should show the caption row with processing state
    expect(screen.getByText('English')).toBeInTheDocument()
    expect(screen.getByText('Processing...')).toBeInTheDocument()
  })

  it('once a language is added, it is removed from the available options dropdown', () => {
    renderComponent()

    // Open manual caption creator
    const addNewButton = screen.getByText(ADD_NEW_BUTTON_TEXT)
    fireEvent.click(addNewButton)

    // Select English and upload
    let selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    fireEvent.change(fileInput, {target: {files: [createValidFile()]}})

    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // English caption should be in the list
    expect(screen.getByText('English')).toBeInTheDocument()

    // Open manual creator again to add another caption
    const addNewButtonAgain = screen.getByText(ADD_NEW_BUTTON_TEXT)
    fireEvent.click(addNewButtonAgain)

    // Open the language dropdown
    selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)

    // English should not be in the dropdown anymore
    const dropdownOptions = screen.queryAllByText('English')
    // Should only find 1 instance (the caption row), not in dropdown
    expect(dropdownOptions).toHaveLength(1)
  })

  it('if captions are provided as props, they are rendered with delete icon', () => {
    const initialSubtitles: Subtitle[] = [
      {locale: 'en', file: {name: 'english.vtt', url: '/url/en'}},
      {locale: 'es', file: {name: 'spanish.vtt', url: '/url/es'}},
    ]

    renderComponent({subtitles: initialSubtitles})

    // Both captions should be rendered
    expect(screen.getByText('English')).toBeInTheDocument()
    expect(screen.getByText('Spanish')).toBeInTheDocument()

    // Delete buttons should be present (look for trash icon buttons)
    expect(screen.getByText('Delete English')).toBeInTheDocument()
    expect(screen.getByText('Delete Spanish')).toBeInTheDocument()
  })

  it('delete icon works and that language is removed from the list', async () => {
    const onUpdateSubtitles = vi.fn()
    const initialSubtitles: Subtitle[] = [
      {locale: 'en', file: {name: 'english.vtt', url: '/url/en'}},
      {locale: 'es', file: {name: 'spanish.vtt', url: '/url/es'}},
    ]

    renderComponent({subtitles: initialSubtitles, onUpdateSubtitles})

    // Both captions should be rendered
    expect(screen.getByText('English')).toBeInTheDocument()
    expect(screen.getByText('Spanish')).toBeInTheDocument()

    // Click the first delete button (English)
    fireEvent.click(screen.getByText('Delete English'))

    // English should be removed from the list
    await waitFor(() => {
      expect(screen.queryByText('English')).not.toBeInTheDocument()
    })

    // Spanish should still be there
    expect(screen.getByText('Spanish')).toBeInTheDocument()
  })

  describe('a11y', () => {
    it('a11y: announces when a caption is added', async () => {
      renderComponent()

      // Open manual caption creator
      fireEvent.click(screen.getByText(ADD_NEW_BUTTON_TEXT))

      // Select a language and file
      const selectPlaceholder = screen.getByText('Select Language')
      fireEvent.click(selectPlaceholder)
      fireEvent.click(screen.getByText('Spanish'))

      const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
      fireEvent.change(fileInput, {target: {files: [createValidFile()]}})

      // Click Upload
      const uploadButton = screen.getByText('Upload')
      fireEvent.click(uploadButton)

      // Should announce the addition
      expect(await screen.findByText(/Captions have been added for Spanish/i)).toBeInTheDocument()
    })

    it('a11y: announces when a caption is deleted', async () => {
      const initialSubtitles: Subtitle[] = [
        {locale: 'en', file: {name: 'english.vtt', url: '/url/en'}},
        {locale: 'fr', file: {name: 'french.vtt', url: '/url/fr'}},
      ]

      renderComponent({subtitles: initialSubtitles})

      // Click the first delete button (English)
      fireEvent.click(screen.getByText('Delete English'))

      // Should announce the deletion
      expect(await screen.findByText(/Captions have been deleted for English/i)).toBeInTheDocument()
    })
  })
})
