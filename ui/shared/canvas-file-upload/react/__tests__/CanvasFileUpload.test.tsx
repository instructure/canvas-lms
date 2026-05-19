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

import '@instructure/canvas-theme'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {vi} from 'vitest'
import CanvasFileUpload from '../CanvasFileUpload'
import type {ContextFile} from '../types'

vi.mock('../hooks/useFileUpload', () => ({
  useFileUpload: () => ({
    uploadingFileNames: new Set<string>(),
    failedFileNames: new Set<string>(),
    clearFailedFile: vi.fn(),
    handleDrop: vi.fn(),
    isUploading: false,
  }),
}))

vi.mock('@canvas/do-fetch-api-effect', () => ({default: vi.fn()}))
vi.mock('@instructure/platform-alerts', () => ({showFlashAlert: vi.fn()}))
vi.mock('../components/CanvasFilesBrowser/CanvasFilesBrowser', () => ({
  default: () => null,
}))

const mockFiles: ContextFile[] = [
  {
    id: 'f1',
    display_name: 'lecture-notes.pdf',
    url: '/files/f1/download',
    size: 204800,
    content_type: 'application/pdf',
  },
  {
    id: 'f2',
    display_name: 'rubric.docx',
    url: '/files/f2/download',
    size: 51200,
    content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  },
]

describe('CanvasFileUpload — Pine failure handling', () => {
  it('shows a Pine-failed file as a warning pill', () => {
    render(
      <CanvasFileUpload
        files={mockFiles}
        onFilesChange={vi.fn()}
        courseId="123"
        initialFailedFileNames={['lecture-notes.pdf']}
      />,
    )
    expect(screen.getByText('lecture-notes.pdf failed')).toBeInTheDocument()
  })

  it('excludes Pine-failed file from the normal file list', () => {
    render(
      <CanvasFileUpload
        files={mockFiles}
        onFilesChange={vi.fn()}
        courseId="123"
        initialFailedFileNames={['lecture-notes.pdf']}
      />,
    )
    // download button absent for the failed file; present for the healthy one
    expect(screen.queryByTestId('download-file-f1')).not.toBeInTheDocument()
    expect(screen.getByTestId('download-file-f2')).toBeInTheDocument()
  })

  it('calls onFilesChange without the failed file when dismiss is clicked', async () => {
    const user = userEvent.setup()
    const onFilesChange = vi.fn()
    render(
      <CanvasFileUpload
        files={mockFiles}
        onFilesChange={onFilesChange}
        courseId="123"
        initialFailedFileNames={['lecture-notes.pdf']}
      />,
    )
    await user.click(screen.getByTestId('dismiss-failed-lecture-notes.pdf'))
    expect(onFilesChange).toHaveBeenCalledWith(
      mockFiles.filter(f => f.display_name !== 'lecture-notes.pdf'),
    )
  })

  it('removes the warning pill after dismissing a Pine failure', async () => {
    const user = userEvent.setup()
    render(
      <CanvasFileUpload
        files={mockFiles}
        onFilesChange={vi.fn()}
        courseId="123"
        initialFailedFileNames={['lecture-notes.pdf']}
      />,
    )
    await user.click(screen.getByTestId('dismiss-failed-lecture-notes.pdf'))
    expect(screen.queryByText('lecture-notes.pdf failed')).not.toBeInTheDocument()
  })

  it('shows non-failed files normally when some files have Pine failures', () => {
    render(
      <CanvasFileUpload
        files={mockFiles}
        onFilesChange={vi.fn()}
        courseId="123"
        initialFailedFileNames={['lecture-notes.pdf']}
      />,
    )
    expect(screen.getByText('rubric.docx')).toBeInTheDocument()
    expect(screen.getByTestId('download-file-f2')).toBeInTheDocument()
  })

  it('renders normally with no initialFailedFileNames', () => {
    render(<CanvasFileUpload files={mockFiles} onFilesChange={vi.fn()} courseId="123" />)
    expect(screen.getByText('lecture-notes.pdf')).toBeInTheDocument()
    expect(screen.getByText('rubric.docx')).toBeInTheDocument()
    expect(screen.queryByText('lecture-notes.pdf failed')).not.toBeInTheDocument()
  })
})
