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

import React from 'react'
import {fireEvent, render, screen} from '@testing-library/react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {FilePreviewModal, FilePreviewModalProps} from '../FilePreviewModal'
import {FAKE_FILES} from '../../../../fixtures/fakeData'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/canvas-studio-player', () => ({
  default: () => <div data-testid="media-player">Media Player</div>,
}))

const defaultProps: FilePreviewModalProps = {
  isOpen: true,
  onClose: vi.fn(),
  item: FAKE_FILES[0],
  collection: FAKE_FILES,
}

const renderComponent = (props?: Partial<FilePreviewModalProps>) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <FilePreviewModal {...defaultProps} {...props} />
    </MockedQueryClientProvider>,
  )
}

describe('FilePreviewModal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    fetchMock.get(/\/media_attachments\/\d+\/info/, {
      body: [],
      headers: {},
      status: 200,
      overwriteRoutes: true,
    })
    window.history.replaceState = vi.fn()
  })

  afterEach(() => {
    fetchMock.reset()
    vi.restoreAllMocks()
    destroyContainer()
  })

  it('renders the modal when open', () => {
    renderComponent()
    expect(screen.getAllByText(defaultProps.item!.display_name)).toHaveLength(4)
  })

  it('calls onClose when close button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('close-button').closest('button') as HTMLElement)
    expect(defaultProps.onClose).toHaveBeenCalledTimes(2)
  })

  it('does not render the modal when closed', () => {
    renderComponent({isOpen: false})
    expect(screen.queryByText('example.pdf')).not.toBeInTheDocument()
  })

  it('renders StudioMediaPlayer when file is a media type', async () => {
    renderComponent({
      item: {...defaultProps.item!, mime_class: 'video', media_entry_id: 'media-123'},
    })
    expect(await screen.findByTestId('media-player')).toBeInTheDocument()
  })

  it('renders the next and previous buttons if collection has more than one item', () => {
    renderComponent()
    expect(screen.getByText('Next')).toBeInTheDocument()
    expect(screen.getByText('Previous')).toBeInTheDocument()
  })

  it('does not render the next and previous buttons if collection has one item', () => {
    renderComponent({collection: [FAKE_FILES[0]]})
    expect(screen.queryByText('Next')).not.toBeInTheDocument()
    expect(screen.queryByText('Previous')).not.toBeInTheDocument()
  })

  it('navigates to next file when next button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('next-button'))
    const header = screen.getAllByText(FAKE_FILES[1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  it('navigates to previous file when previous button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('previous-button'))
    const header = screen.getAllByText(FAKE_FILES[FAKE_FILES.length - 1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  // userEvent.type is flaky
  it('navigates to next file when right arrow key is pressed', async () => {
    renderComponent()
    const modal = screen.getByTestId('file-preview-modal')
    fireEvent.keyDown(modal, {key: 'ArrowRight'})
    const header = screen.getAllByText(FAKE_FILES[1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  it('navigates to previous file when left arrow key is pressed', async () => {
    renderComponent()
    const modal = screen.getByTestId('file-preview-modal')
    fireEvent.keyDown(modal, {key: 'ArrowLeft'})
    const header = screen.getAllByText(FAKE_FILES[FAKE_FILES.length - 1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  describe('with keyboard shortcuts disabled', () => {
    beforeAll(() => {
      ENV.disable_keyboard_shortcuts = true
    })

    afterAll(() => {
      ENV.disable_keyboard_shortcuts = false
    })

    it('does not navigate to next file when right arrow key is pressed', async () => {
      renderComponent()
      const modal = screen.getByTestId('file-preview-modal')
      fireEvent.keyDown(modal, {key: 'ArrowRight'})
      expect(screen.getByTestId('file-header')).toHaveTextContent(FAKE_FILES[0].display_name)
    })

    it('does not navigate to previous file when left arrow key is pressed', async () => {
      renderComponent()
      const modal = screen.getByTestId('file-preview-modal')
      fireEvent.keyDown(modal, {key: 'ArrowLeft'})
      expect(screen.getByTestId('file-header')).toHaveTextContent(FAKE_FILES[0].display_name)
    })
  })

  describe('when item is null (file not found)', () => {
    it('renders FileNotFound component', () => {
      renderComponent({
        item: null,
        error: 'File not found',
      })

      expect(screen.getByText('File Not Found')).toBeInTheDocument()
      expect(screen.getByTestId('file-not-found-message')).toBeInTheDocument()
    })

    it('disables file info button when no file', () => {
      renderComponent({
        item: null,
        error: 'File not found',
      })

      const infoButton = document.getElementById('file-info-button')
      expect(infoButton).toBeDisabled()
    })

    it('disables download button when no file', () => {
      renderComponent({
        item: null,
        error: 'File not found',
      })

      const downloadButton = document.getElementById('download-icon-button')
      expect(downloadButton).toBeDisabled()
    })

    it('does not render FilePreviewTray when no file', () => {
      renderComponent({
        item: null,
        error: 'File not found',
      })

      const infoButton = document.getElementById('file-info-button')
      expect(infoButton).toBeDisabled()
      expect(screen.queryByText('File Information')).not.toBeInTheDocument()
    })
  })

  describe('when error is provided', () => {
    it('renders FileNotFound component even with valid item', () => {
      renderComponent({
        item: FAKE_FILES[0],
        error: 'Custom error message',
      })

      expect(screen.getByText('File Not Found')).toBeInTheDocument()
      expect(screen.queryByTestId('file-preview')).not.toBeInTheDocument()
    })
  })

  describe('showNavigationButtons prop', () => {
    it('shows navigation buttons when showNavigationButtons is true and collection has multiple files', () => {
      renderComponent({
        showNavigationButtons: true,
        collection: FAKE_FILES.slice(0, 3), // Multiple files
      })

      expect(screen.getByTestId('previous-button')).toBeInTheDocument()
      expect(screen.getByTestId('next-button')).toBeInTheDocument()
    })

    it('hides navigation buttons when showNavigationButtons is false', () => {
      renderComponent({
        showNavigationButtons: false,
        collection: FAKE_FILES.slice(0, 3), // Multiple files
      })

      expect(screen.queryByTestId('previous-button')).not.toBeInTheDocument()
      expect(screen.queryByTestId('next-button')).not.toBeInTheDocument()
    })

    it('hides navigation buttons when no current item', () => {
      renderComponent({
        item: null,
        showNavigationButtons: true,
        collection: FAKE_FILES.slice(0, 3),
      })

      expect(screen.queryByTestId('previous-button')).not.toBeInTheDocument()
      expect(screen.queryByTestId('next-button')).not.toBeInTheDocument()
    })

    it('hides navigation buttons when collection has only one file', () => {
      renderComponent({
        showNavigationButtons: true,
        collection: [FAKE_FILES[0]],
      })

      expect(screen.queryByTestId('previous-button')).not.toBeInTheDocument()
      expect(screen.queryByTestId('next-button')).not.toBeInTheDocument()
    })
  })

  describe('file info button interaction', () => {
    it('enables file info button when file is available', () => {
      renderComponent({
        item: FAKE_FILES[0],
      })

      const infoButton = document.getElementById('file-info-button')
      expect(infoButton).not.toBeDisabled()
    })

    it('opens file info tray when button is clicked and file is available', async () => {
      renderComponent({
        item: FAKE_FILES[0],
      })

      const infoButton = document.getElementById('file-info-button')?.closest('button')
      expect(infoButton).not.toBeDisabled()
      await userEvent.click(infoButton as HTMLElement)
      expect(screen.getByLabelText('File Information')).toBeInTheDocument()
    })

    it('renders FilePreviewTray only when currentItem exists', async () => {
      const {rerender} = renderComponent({
        item: FAKE_FILES[0],
      })

      const infoButton = document.getElementById('file-info-button')?.closest('button')
      await userEvent.click(infoButton as HTMLElement)

      rerender(
        <MockedQueryClientProvider client={queryClient}>
          <FilePreviewModal {...defaultProps} item={null} error="File not found" />
        </MockedQueryClientProvider>,
      )
      expect(screen.queryByTestId('tray-close-button')).not.toBeInTheDocument()
    })
  })

  describe('modal title handling', () => {
    it('shows file name when item is available', () => {
      renderComponent({
        item: FAKE_FILES[0],
      })

      expect(screen.getByTestId('file-header')).toHaveTextContent(FAKE_FILES[0].display_name)
    })

    it('shows "File" as fallback when item is null', () => {
      renderComponent({
        item: null,
        error: 'File not found',
      })

      expect(screen.getByTestId('file-header')).toHaveTextContent('File')
    })
  })

  describe('keyboard navigation with new features', () => {
    it('hides navigation buttons when showNavigationButtons is false', () => {
      renderComponent({
        showNavigationButtons: false,
        collection: FAKE_FILES.slice(0, 3),
      })

      expect(screen.queryByLabelText('Previous file')).not.toBeInTheDocument()
      expect(screen.queryByLabelText('Next file')).not.toBeInTheDocument()
    })

    it('disables keyboard navigation when showNavigationButtons is false', async () => {
      renderComponent({
        showNavigationButtons: false,
        collection: FAKE_FILES.slice(0, 3),
      })

      const modal = screen.getByTestId('file-preview-modal')
      const initialFileName = FAKE_FILES[0].display_name

      expect(screen.getByTestId('file-header')).toHaveTextContent(initialFileName)

      fireEvent.keyDown(modal, {key: 'ArrowRight'})
      fireEvent.keyDown(modal, {key: 'ArrowLeft'})

      expect(screen.getByTestId('file-header')).toHaveTextContent(initialFileName)
      expect(window.history.replaceState).not.toHaveBeenCalled()
    })

    it('disables keyboard navigation when no current item', async () => {
      renderComponent({
        item: null,
        showNavigationButtons: true,
        collection: FAKE_FILES.slice(0, 3),
      })

      const modal = screen.getByTestId('file-preview-modal')

      fireEvent.keyDown(modal, {key: 'ArrowRight'})
      fireEvent.keyDown(modal, {key: 'ArrowLeft'})

      expect(screen.getByText('File Not Found')).toBeInTheDocument()
    })
  })

  describe('when keyboard shortcuts are disabled', () => {
    beforeAll(() => {
      ENV.disable_keyboard_shortcuts = true
    })

    afterAll(() => {
      ENV.disable_keyboard_shortcuts = false
    })

    it('does not navigate to next file when right arrow key is pressed', async () => {
      renderComponent()
      const modal = screen.getByTestId('file-preview-modal')
      fireEvent.keyDown(modal, {key: 'ArrowRight'})
      expect(screen.getByTestId('file-header')).toHaveTextContent(FAKE_FILES[0].display_name)
    })

    it('does not navigate to previous file when left arrow key is pressed', async () => {
      renderComponent()
      const modal = screen.getByTestId('file-preview-modal')
      fireEvent.keyDown(modal, {key: 'ArrowLeft'})
      expect(screen.getByTestId('file-header')).toHaveTextContent(FAKE_FILES[0].display_name)
    })
  })
})
