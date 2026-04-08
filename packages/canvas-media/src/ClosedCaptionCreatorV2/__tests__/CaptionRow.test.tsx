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

import {fireEvent, render, screen} from '@testing-library/react'
import {vi} from 'vitest'
import {CaptionRow, type CaptionRowProps} from '../CaptionRow'

function renderComponent(props: CaptionRowProps) {
  return render(<CaptionRow {...props} />)
}

describe('<CaptionRow />', () => {
  it('renders uploaded caption row with delete action', () => {
    const onDelete = vi.fn()
    renderComponent({
      workflow_state: 'ready',
      captionName: 'English Caption',
      onDelete,
    })

    expect(screen.getByText('English Caption')).toBeInTheDocument()
    expect(screen.getByText('Delete English Caption')).toBeInTheDocument()

    fireEvent.click(screen.getByText('Delete English Caption'))
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('uploaded caption: shows download link with href and filename attributes', () => {
    const onDelete = vi.fn()

    renderComponent({
      workflow_state: 'ready',
      captionName: 'Spanish Caption',
      url: 'https://example.com/es.srt',
      filename: 'spanish_es.srt',
      onDelete,
    })

    const downloadLink = screen.getByText('Download Spanish Caption').closest('a')
    expect(downloadLink).toBeInTheDocument()
    expect(downloadLink).toHaveAttribute('href', 'https://example.com/es.srt')
    expect(downloadLink).toHaveAttribute('download', 'spanish_es.srt')
  })

  it('uploaded caption: download button always shown in ready state', () => {
    renderComponent({
      workflow_state: 'ready',
      captionName: 'Spanish Caption',
      onDelete: vi.fn(),
    })

    expect(screen.getByText('Download Spanish Caption')).toBeInTheDocument()
  })

  it('renders processing state properly displaying text', () => {
    renderComponent({
      workflow_state: 'processing',
      captionName: 'French Caption',
    })

    expect(screen.getByText('French Caption')).toBeInTheDocument()
    expect(screen.getByText('Processing...')).toBeInTheDocument()
    expect(screen.queryByText(/delete/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/download/i)).not.toBeInTheDocument()
  })

  it('renders failed state', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      errorMessage: 'File size too large',
    })

    expect(screen.getByText('German Caption')).toBeInTheDocument()
    expect(screen.getByText('File size too large')).toBeInTheDocument()
  })

  it('failed state: shows retry button and calls onRetry when clicked', () => {
    const onRetry = vi.fn()
    renderComponent({
      workflow_state: 'failed',
      captionName: 'Spanish Caption',
      errorMessage: 'Upload Failed',
      onRetry,
    })

    expect(screen.getByText('Spanish Caption')).toBeInTheDocument()
    expect(screen.getByText('Upload Failed')).toBeInTheDocument()

    const retryButton = screen.getByText('Retry Spanish Caption')
    expect(retryButton).toBeInTheDocument()

    fireEvent.click(retryButton)
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('failed state: shows delete button and calls onDelete when clicked', () => {
    const onDelete = vi.fn()
    renderComponent({
      workflow_state: 'failed',
      captionName: 'Spanish Caption',
      errorMessage: 'Caption generation failed',
      onDelete,
    })

    const deleteButton = screen.getByText('Delete Spanish Caption')
    expect(deleteButton).toBeInTheDocument()

    fireEvent.click(deleteButton)
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('failed state: does not show delete button when onDelete is not provided', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'French Caption',
      errorMessage: 'Caption generation failed',
    })

    expect(screen.queryByText('Delete French Caption')).not.toBeInTheDocument()
  })

  it('failed state: does not show retry button when onRetry is not provided', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'French Caption',
      errorMessage: 'Delete Failed',
    })

    expect(screen.queryByText(/retry/i)).not.toBeInTheDocument()
  })

  it('inherited state: disabled delete action and has proper aria label on delete button', () => {
    const onDelete = vi.fn()
    renderComponent({
      workflow_state: 'ready',
      captionName: 'Inherited Caption',
      isInherited: true,
      onDelete,
    })

    expect(screen.getByText('Inherited Caption')).toBeInTheDocument()

    const inheritedMessages = screen.getAllByText(
      /Captions inherited from a parent course cannot be removed/i,
    )
    expect(inheritedMessages.length).toBeGreaterThan(0)
  })
})
