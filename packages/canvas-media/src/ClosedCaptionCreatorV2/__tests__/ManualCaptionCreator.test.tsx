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
import {ManualCaptionCreator} from '../ManualCaptionCreator'

const LIVE_REGION_ID = 'flash_screenreader_holder'

const mockLanguages = [
  {id: 'en', label: 'English'},
  {id: 'es', label: 'Spanish'},
  {id: 'fr', label: 'French'},
]

function createValidFile(name = 'captions.vtt', size = 1000): File {
  const content = new Array(size).fill('a').join('')
  return new File([content], name, {type: 'text/vtt'})
}

function createLargeFile(): File {
  // Create file larger than 295000 bytes
  const content = new Array(300000).fill('a').join('')
  return new File([content], 'large-captions.vtt', {type: 'text/vtt'})
}

function renderComponent(overrideProps = {}) {
  const defaultProps = {
    languages: mockLanguages,
    onPrimary: vi.fn(),
    onCancel: vi.fn(),
    liveRegion: () => document.getElementById(LIVE_REGION_ID),
  }

  return {
    ...render(<ManualCaptionCreator {...defaultProps} {...overrideProps} />),
    props: {...defaultProps, ...overrideProps},
  }
}

describe('<ManualCaptionCreator />', () => {
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

  it('shows language required error when no language is selected', () => {
    const onPrimary = vi.fn()
    renderComponent({onPrimary})

    // Click Upload without selecting language
    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // Should show language error
    expect(screen.getAllByText('Please select a language').length).toBeGreaterThan(0)
    expect(onPrimary).not.toHaveBeenCalled()
  })

  it('shows file required error when no file is selected', () => {
    const onPrimary = vi.fn()
    renderComponent({onPrimary})

    // Select a language first - click on placeholder text to open, then click option
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    // Click Upload without selecting file
    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // Should show file error
    expect(screen.getAllByText('Please select a file before uploading.').length).toBeGreaterThan(0)
    expect(onPrimary).not.toHaveBeenCalled()
  })

  it('shows file validation error when too large file is selected', async () => {
    renderComponent()

    // Get the hidden file input and simulate file selection
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    const largeFile = createLargeFile()

    fireEvent.change(fileInput, {target: {files: [largeFile]}})

    // Should show size limit error
    expect((await screen.findAllByText(/exceeds the 295000 Byte limit/i)).length).toBeGreaterThan(0)
  })

  it('calls onPrimary with correct args when both language and valid file are selected', () => {
    const onPrimary = vi.fn()
    renderComponent({onPrimary})

    // Select a language - click on placeholder text to open, then click option
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('Spanish'))

    // Select a valid file
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    const validFile = createValidFile()
    fireEvent.change(fileInput, {target: {files: [validFile]}})

    // Click Upload
    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // onPrimary should be called with languageId and file
    expect(onPrimary).toHaveBeenCalledWith('es', validFile)
  })

  it('cancel button calls onCancel', async () => {
    const onCancel = vi.fn()
    renderComponent({onCancel})

    const cancelButton = screen.getByText('Cancel')
    fireEvent.click(cancelButton)

    await waitFor(() => {
      expect(onCancel).toHaveBeenCalledTimes(1)
    })
  })

  it('language error clears when language selected', async () => {
    renderComponent()

    // Click Upload to show error
    const uploadButton = screen.getByText('Upload')
    fireEvent.click(uploadButton)

    // Error should be visible
    expect(screen.getAllByText('Please select a language').length).toBeGreaterThan(0)

    // Select a language - click on placeholder text to open, then click option
    const selectPlaceholder = screen.getByText('Select Language')
    fireEvent.click(selectPlaceholder)
    fireEvent.click(screen.getByText('English'))

    // Error should be cleared
    expect(screen.queryByText('Please select a language')).not.toBeInTheDocument()
  })

  it('file validation error clears when valid file selected', async () => {
    renderComponent()

    // Select a large file to trigger error
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    const largeFile = createLargeFile()
    fireEvent.change(fileInput, {target: {files: [largeFile]}})

    // Error should be visible
    expect((await screen.findAllByText(/exceeds the 295000 Byte limit/i)).length).toBeGreaterThan(0)

    // Select a valid file
    const validFile = createValidFile()
    fireEvent.change(fileInput, {target: {files: [validFile]}})

    // Error should be cleared
    await waitFor(() => {
      expect(screen.queryByText(/exceeds the 295000 Byte limit/i)).not.toBeInTheDocument()
    })
  })

  describe('a11y', () => {
    it('a11y: alerts error messages when they appear', async () => {
      renderComponent()

      // Click Upload without selections to trigger errors
      const uploadButton = screen.getByText('Upload')
      fireEvent.click(uploadButton)

      // Check that Alert components are rendered (screen reader announcements)
      const alerts = document.querySelectorAll('[role="alert"]')

      await waitFor(() => {
        expect(alerts.length).toBeGreaterThan(0)
      })
    })

    it('a11y: button has aria-describedby linking to format hint and file status', async () => {
      renderComponent()

      const chooseFileButton = screen.getByText(/choose file/i).closest('button')
      expect(chooseFileButton).toHaveAttribute('aria-describedby', 'cc-file-hint cc-file-status')

      // Hint element should exist with correct id
      expect(document.getElementById('cc-file-hint')).toHaveTextContent(/SRT or WebVTT/i)

      // Status element should show "No file chosen" initially
      expect(document.getElementById('cc-file-status')).toHaveTextContent(/no file chosen/i)

      // Select a file
      const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
      const validFile = createValidFile('my-captions.vtt')
      fireEvent.change(fileInput, {target: {files: [validFile]}})

      // Status element should now show the selected file name
      expect(await screen.findByText('my-captions.vtt')).toBeInTheDocument()
      expect(document.getElementById('cc-file-status')).toHaveTextContent('my-captions.vtt')
    })
  })

  describe('Pendo tracking', () => {
    const mockTrack = vi.fn()

    beforeEach(() => {
      ;(window as any).canvasUsageMetrics = {track: mockTrack}
    })

    afterEach(() => {
      delete (window as any).canvasUsageMetrics
    })

    it('fires canvas_caption_validation_error missing_language when no language is selected', async () => {
      renderComponent()
      fireEvent.click(screen.getByText('Upload'))
      await waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('canvas_caption_validation_error', {
          type: 'track',
          flow_type: 'upload_file',
          error_type: 'missing_language',
        })
      })
    })

    it('fires canvas_caption_validation_error missing_file when no file is selected', async () => {
      renderComponent()
      fireEvent.click(screen.getByText('Select Language'))
      fireEvent.click(screen.getByText('English'))
      fireEvent.click(screen.getByText('Upload'))
      await waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('canvas_caption_validation_error', {
          type: 'track',
          flow_type: 'upload_file',
          error_type: 'missing_file',
        })
      })
    })

    it('fires canvas_caption_validation_error file_too_large when large file selected', async () => {
      renderComponent()
      const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
      fireEvent.change(fileInput, {target: {files: [createLargeFile()]}})
      await waitFor(() => {
        expect(mockTrack).toHaveBeenCalledWith('canvas_caption_validation_error', {
          type: 'track',
          flow_type: 'upload_file',
          error_type: 'file_too_large',
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

      it('when file is selected', async () => {
        const onDirtyStateChanged = vi.fn()
        renderComponent({onDirtyStateChanged})

        const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
        const validFile = createValidFile('my-captions.vtt')
        fireEvent.change(fileInput, {target: {files: [validFile]}})

        await waitFor(() => {
          expect(onDirtyStateChanged).toHaveBeenCalledWith(true)
        })
      })
    })
  })
})
