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

    expect(screen.getByText(/^english caption$/i)).toBeInTheDocument()
    expect(screen.getByText(/^delete english caption$/i)).toBeInTheDocument()

    fireEvent.click(screen.getByText(/^delete english caption$/i))
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

    const downloadLink = screen.getByText(/download spanish caption/i).closest('a')
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

    expect(screen.getByText(/download spanish caption/i)).toBeInTheDocument()
  })

  it('renders processing state properly displaying text', () => {
    renderComponent({
      workflow_state: 'processing',
      captionName: 'French Caption',
    })

    expect(screen.getByText(/french caption/i)).toBeInTheDocument()
    expect(screen.getByText(/processing\.\.\./i)).toBeInTheDocument()
    expect(screen.queryByText(/delete/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/download/i)).not.toBeInTheDocument()
  })

  it('failed upload: shows "Upload failed"', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      failedOperation: 'upload',
    })

    expect(screen.getByText(/german caption/i)).toBeInTheDocument()
    expect(screen.getByText(/upload failed/i)).toBeInTheDocument()
  })

  it('failed ASR: shows "Generation failed"', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      failedOperation: 'asr',
    })

    expect(screen.getByLabelText(/german caption, generation failed/i)).toBeInTheDocument()
  })

  it('failed delete: shows "Delete failed"', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      failedOperation: 'delete',
    })

    expect(screen.getByLabelText(/german caption, delete failed/i)).toBeInTheDocument()
  })

  it('server-side ASR failure (no failedOperation): shows "Generation failed"', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      asr: true,
    })

    expect(screen.getByLabelText(/german caption, generation failed/i)).toBeInTheDocument()
  })

  it('failed state: shows retry button and calls onRetry when clicked', () => {
    const onRetry = vi.fn()
    renderComponent({
      workflow_state: 'failed',
      captionName: 'Spanish Caption',
      failedOperation: 'upload',
      onRetry,
    })

    expect(screen.getByText(/^spanish caption$/i)).toBeInTheDocument()
    expect(screen.getByText(/^upload failed$/i)).toBeInTheDocument()

    const retryButton = screen.getByText(/^retry spanish caption$/i)
    expect(retryButton).toBeInTheDocument()

    fireEvent.click(retryButton)
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('failed state: shows delete button and calls onDelete when clicked', () => {
    const onDelete = vi.fn()
    renderComponent({
      workflow_state: 'failed',
      captionName: 'Spanish Caption',
      failedOperation: 'asr',
      onDelete,
    })

    const deleteButton = screen.getByText(/delete spanish caption/i)
    expect(deleteButton).toBeInTheDocument()

    fireEvent.click(deleteButton)
    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('failed state: does not show delete button when onDelete is not provided', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'French Caption',
      failedOperation: 'asr',
    })

    expect(screen.queryByText(/delete french caption/i)).not.toBeInTheDocument()
  })

  it('failed state: does not show retry button when onRetry is not provided', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'French Caption',
      failedOperation: 'delete',
    })

    expect(screen.queryByText(/retry/i)).not.toBeInTheDocument()
  })

  it('processing state: row aria-label includes caption name and status', () => {
    renderComponent({
      workflow_state: 'processing',
      captionName: 'French Caption',
    })

    expect(screen.getByLabelText(/french caption, processing\.\.\./i)).toBeInTheDocument()
  })

  it('failed state: row aria-label includes caption name and status text', () => {
    renderComponent({
      workflow_state: 'failed',
      captionName: 'German Caption',
      failedOperation: 'asr',
    })

    expect(screen.getByLabelText(/german caption, generation failed/i)).toBeInTheDocument()
  })

  it('ready state: row aria-label is just the caption name', () => {
    renderComponent({
      workflow_state: 'ready',
      captionName: 'English Caption',
      onDelete: vi.fn(),
    })

    expect(screen.getByLabelText(/english caption/i)).toBeInTheDocument()
  })

  it('inherited state: disabled delete action and has proper aria label on delete button', () => {
    const onDelete = vi.fn()
    renderComponent({
      workflow_state: 'ready',
      captionName: 'Inherited Caption',
      isInherited: true,
      onDelete,
    })

    expect(screen.getByText(/^inherited caption$/i)).toBeInTheDocument()

    const inheritedMessages = screen.getAllByText(
      /Captions inherited from a parent course cannot be removed/i,
    )
    expect(inheritedMessages.length).toBeGreaterThan(0)
  })
})
