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
import {HttpResponse, http} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

const LIVE_REGION_ID = 'flash_screenreader_holder'

const TEST_UPLOAD_CONFIG = {
  mediaObjectId: 'media123',
  origin: 'http://localhost:3000',
  headers: {Authorization: 'Bearer token'},
}

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
  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))

  beforeEach(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = LIVE_REGION_ID
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  const ADD_NEW_BUTTON_TEXT = 'Add New'
  const REQUEST_BUTTON_TEXT = 'Request'

  afterEach(() => {
    const liveRegion = document.getElementById(LIVE_REGION_ID)
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
    server.resetHandlers()
    vi.clearAllMocks()
  })

  afterAll(() => server.close())

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

  it('if language and file selected it uploads and shows the language in the list', async () => {
    // Mock successful upload
    server.use(
      http.put('**/api/media_objects/*/media_tracks', () => HttpResponse.json({data: 'success'})),
    )

    renderComponent({uploadConfig: TEST_UPLOAD_CONFIG})

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

    // Wait for English to appear in the list (uploaded)
    expect(await screen.findByText('English')).toBeInTheDocument()
  })

  it('once a language is added and uploaded, it is removed from the available options dropdown', async () => {
    // Mock successful upload
    server.use(
      http.put('**/api/media_objects/*/media_tracks', () => HttpResponse.json({data: 'success'})),
    )

    renderComponent({uploadConfig: TEST_UPLOAD_CONFIG})

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

    // Wait for English caption to be in the list (uploaded)
    expect(await screen.findByText('English')).toBeInTheDocument()

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
    server.use(
      http.put('/api/media_objects/*/media_tracks', () => HttpResponse.json({data: 'success'})),
    )

    const onUpdateSubtitles = vi.fn()
    const initialSubtitles: Subtitle[] = [
      {locale: 'en', file: {name: 'english.vtt', url: '/url/en'}},
      {locale: 'es', file: {name: 'spanish.vtt', url: '/url/es'}},
    ]

    renderComponent({
      subtitles: initialSubtitles,
      onUpdateSubtitles,
      uploadConfig: TEST_UPLOAD_CONFIG,
    })

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
      server.use(
        http.put('/api/media_objects/*/media_tracks', () => HttpResponse.json({data: 'success'})),
      )

      renderComponent({
        uploadConfig: TEST_UPLOAD_CONFIG,
      })

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

      screen.debug()

      // Wait for a11y announcement for upload to complete
      await screen.findByText('Captions have been added for Spanish')
    })

    it('a11y: announces when a caption is deleted', async () => {
      server.use(
        http.put('/api/media_objects/*/media_tracks', () => HttpResponse.json({data: 'success'})),
      )

      const initialSubtitles: Subtitle[] = [
        {locale: 'en', file: {name: 'english.vtt', url: '/url/en'}},
        {locale: 'fr', file: {name: 'french.vtt', url: '/url/fr'}},
      ]

      renderComponent({subtitles: initialSubtitles, uploadConfig: TEST_UPLOAD_CONFIG})

      // Click the first delete button (English)
      fireEvent.click(screen.getByText('Delete English'))

      await screen.findByText('Captions have been deleted for English')
    })

    it('a11y: announces when a caption upload fails', async () => {
      server.use(
        http.put('/api/media_objects/*/media_tracks', () =>
          HttpResponse.json({error: 'Anything'}, {status: 400}),
        ),
      )

      renderComponent({
        uploadConfig: TEST_UPLOAD_CONFIG,
      })

      // Open manual caption creator
      fireEvent.click(screen.getByText(ADD_NEW_BUTTON_TEXT))

      // Select a language and file
      const selectPlaceholder = screen.getByText('Select Language')
      fireEvent.click(selectPlaceholder)
      fireEvent.click(screen.getByText('German'))

      fireEvent.change(document.querySelector('input[type="file"]') as HTMLInputElement, {
        target: {files: [createValidFile()]},
      })

      // Click Upload
      const uploadButton = screen.getByText('Upload')
      fireEvent.click(uploadButton)

      expect(await screen.findByText('Failed')).toBeInTheDocument()

      await screen.findByText('German caption upload failed')
    })

    it('a11y: announces when a caption delete fails', async () => {
      server.use(
        http.put('/api/media_objects/*/media_tracks', () =>
          HttpResponse.json({error: 'Delete failed'}, {status: 400}),
        ),
      )

      const initialSubtitles: Subtitle[] = [
        {locale: 'fr', file: {name: 'french.vtt', url: '/url/fr'}},
      ]

      renderComponent({
        subtitles: initialSubtitles,
        uploadConfig: TEST_UPLOAD_CONFIG,
      })

      // Click delete button
      fireEvent.click(screen.getByText('Delete French'))

      // Wait for a11y announcement with formatted error message (using template)
      await screen.findByText('French caption delete failed')

      // Caption should still be visible with error message
      expect(screen.getByText('French')).toBeInTheDocument()
      expect(screen.getByText('Failed')).toBeInTheDocument()
    })
  })

  // Skipped: ARC-11427
  it.skip('updates displayed subtitles when prop changes after mount', async () => {
    const onUpdateSubtitles = vi.fn()

    // Start with empty subtitles
    const {rerender, props} = renderComponent({
      subtitles: [],
      onUpdateSubtitles,
    })

    // Should show "Add New" button (no subtitles yet)
    expect(screen.getByText(ADD_NEW_BUTTON_TEXT)).toBeInTheDocument()
    expect(screen.queryByText('English')).not.toBeInTheDocument()

    // Simulate async subtitle loading (like iframe response)
    const newSubtitles: Subtitle[] = [
      {locale: 'en', file: {name: 'English'}},
      {locale: 'es', file: {name: 'Spanish'}},
    ]

    rerender(<ClosedCaptionPanelV2 {...props} subtitles={newSubtitles} />)

    // Should now show both captions
    await waitFor(() => {
      expect(screen.getByText('English')).toBeInTheDocument()
      expect(screen.getByText('Spanish')).toBeInTheDocument()
    })
  })
})
