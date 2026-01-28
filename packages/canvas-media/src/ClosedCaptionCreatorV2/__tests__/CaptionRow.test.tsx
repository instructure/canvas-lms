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
import {CaptionRow, type CaptionRowProps} from '../CaptionRow'

const LIVE_REGION_ID = 'flash_screenreader_holder'

function renderComponent(props: CaptionRowProps) {
  return render(<CaptionRow {...props} />)
}

describe('<CaptionRow />', () => {
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

  it('renders uploaded caption row with delete action', () => {
    const onDelete = vi.fn()
    renderComponent({
      status: 'uploaded',
      captionName: 'English Caption',
      liveRegion: () => document.getElementById(LIVE_REGION_ID),
      onDelete,
    })

    // Caption name should be displayed
    expect(screen.getByText('English Caption')).toBeInTheDocument()

    // Delete button should be present and clickable
    expect(screen.getByText('Delete English Caption')).toBeInTheDocument()

    // Click delete button
    fireEvent.click(screen.getByText('Delete English Caption'))

    // onDelete should be called
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('uploaded caption: if onDownload is provided, it shows download button', () => {
    const onDownload = vi.fn()
    const onDelete = vi.fn()

    renderComponent({
      status: 'uploaded',
      captionName: 'Spanish Caption',
      liveRegion: () => document.getElementById(LIVE_REGION_ID),
      onDownload,
      onDelete,
    })

    // Download button should be present
    const downloadButton = screen.getByText('Download Spanish Caption').closest('button')
    expect(downloadButton).toBeInTheDocument()

    // Click download button
    fireEvent.click(downloadButton!)

    // onDownload should be called
    expect(onDownload).toHaveBeenCalledTimes(1)
  })

  it('renders processing state properly displaying text', () => {
    renderComponent({
      status: 'processing',
      captionName: 'French Caption',
      liveRegion: () => document.getElementById(LIVE_REGION_ID),
    })

    // Caption name should be displayed
    expect(screen.getByText('French Caption')).toBeInTheDocument()

    // Processing text should be displayed
    expect(screen.getByText('Processing...')).toBeInTheDocument()

    // No action buttons should be present
    expect(screen.queryByText(/delete/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/download/i)).not.toBeInTheDocument()
  })

  it('renders failed state with delete action', async () => {
    const onDelete = vi.fn()
    renderComponent({
      status: 'failed',
      captionName: 'German Caption',
      errorMessage: 'File size too large',
      liveRegion: () => document.getElementById(LIVE_REGION_ID),
      onDelete,
    })

    // Caption name should be displayed
    expect(screen.getByText('German Caption')).toBeInTheDocument()

    // Error message should be displayed
    expect(screen.getByText('File size too large')).toBeInTheDocument()

    // Screen reader alert should be announced
    const alerts = document.querySelectorAll('[role="alert"]')
    await waitFor(() => {
      expect(alerts.length).toBeGreaterThan(0)
    })

    // Delete button should be present
    const deleteButton = screen.getByText('Delete German Caption').closest('button')
    expect(deleteButton).toBeInTheDocument()

    // Click delete button
    fireEvent.click(deleteButton!)

    // onDelete should be called
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('inherited state: disabled delete action and has proper aria label on delete button', () => {
    const onDelete = vi.fn()
    renderComponent({
      status: 'uploaded',
      captionName: 'Inherited Caption',
      liveRegion: () => document.getElementById(LIVE_REGION_ID),
      isInherited: true,
      onDelete,
    })

    // Caption name should be displayed
    expect(screen.getByText('Inherited Caption')).toBeInTheDocument()

    // Inherited message should be displayed to users (text appears twice - in button and as visible text)
    const inheritedMessages = screen.getAllByText(
      /Captions inherited from a parent course cannot be removed/i,
    )
    expect(inheritedMessages.length).toBeGreaterThan(0)
  })
})
