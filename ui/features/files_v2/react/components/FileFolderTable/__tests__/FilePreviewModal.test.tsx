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
import '@testing-library/jest-dom/extend-expect'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {FilePreviewModal, FilePreviewModalProps} from '../FilePreviewModal'
import {FAKE_FILES} from '../../../../fixtures/fakeData'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/canvas-studio-player', () => {
  const mockDefault = jest.fn(() => <div data-testid="media-player">Media Player</div>)
  return {
    __esModule: true,
    default: mockDefault,
  }
})

const defaultProps: FilePreviewModalProps = {
  isOpen: true,
  onClose: jest.fn(),
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
    jest.clearAllMocks()
    fetchMock.get(/\/media_attachments\/\d+\/info/, {
      body: [],
      headers: {},
      status: 200,
      overwriteRoutes: true,
    })
    window.history.replaceState = jest.fn()
  })

  afterEach(() => {
    fetchMock.reset()
    jest.restoreAllMocks()
    destroyContainer()
  })

  it('renders the modal when open', () => {
    renderComponent()
    expect(screen.getAllByText(defaultProps.item.display_name)).toHaveLength(4)
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
      item: {...defaultProps.item, mime_class: 'video', media_entry_id: 'media-123'},
    })
    expect(await screen.findByTestId('media-player')).toBeInTheDocument()
  })

  it('renders NoFilePreviewAvailable for unsupported file types', () => {
    renderComponent({item: {...defaultProps.item, mime_class: 'unsupported'}})
    expect(screen.getByText(/no preview available/i)).toBeInTheDocument()
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
    await userEvent.click(screen.getByRole('button', {name: /next/i}))
    const header = screen.getAllByText(FAKE_FILES[1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  it('navigates to previous file when previous button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: /previous/i}))
    const header = screen.getAllByText(FAKE_FILES[FAKE_FILES.length - 1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  // userEvent.type is flaky
  it('navigates to next file when right arrow key is pressed', async () => {
    renderComponent()
    const modal = screen.getByRole('dialog')
    fireEvent.keyDown(modal, {key: 'ArrowRight'})
    const header = screen.getAllByText(FAKE_FILES[1].display_name)[0]
    expect(header).toBeInTheDocument()
    expect(window.history.replaceState).toHaveBeenCalled()
  })

  it('navigates to previous file when left arrow key is pressed', async () => {
    renderComponent()
    const modal = screen.getByRole('dialog')
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
      const modal = screen.getByRole('dialog')
      fireEvent.keyDown(modal, {key: 'ArrowRight'})
      expect(screen.getByRole('heading', {name: FAKE_FILES[0].display_name})).toBeInTheDocument()
    })

    it('does not navigate to previous file when left arrow key is pressed', async () => {
      renderComponent()
      const modal = screen.getByRole('dialog')
      fireEvent.keyDown(modal, {key: 'ArrowLeft'})
      expect(screen.getByRole('heading', {name: FAKE_FILES[0].display_name})).toBeInTheDocument()
    })
  })
})
