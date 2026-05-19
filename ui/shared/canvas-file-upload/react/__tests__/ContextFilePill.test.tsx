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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {vi} from 'vitest'
import ContextFilePill from '../ContextFilePill'
import type {ContextFile} from '../types'

const makeFile = (overrides: Partial<ContextFile> = {}): ContextFile => ({
  id: '1',
  display_name: 'test-file.pdf',
  url: 'http://example.com/test-file.pdf',
  size: 1024,
  content_type: 'application/pdf',
  ...overrides,
})

describe('ContextFilePill', () => {
  it('renders the filename', () => {
    render(<ContextFilePill file={makeFile()} />)
    expect(screen.getByText('test-file.pdf')).toBeInTheDocument()
  })

  it('renders a download button with the correct href', () => {
    render(<ContextFilePill file={makeFile()} />)
    const downloadBtn = screen.getByTestId('download-file-1')
    expect(downloadBtn).toHaveAttribute('href', 'http://example.com/test-file.pdf')
  })

  it('renders a remove button when onRemove is provided', () => {
    render(<ContextFilePill file={makeFile()} onRemove={vi.fn()} />)
    expect(screen.getByTestId('remove-file-1')).toBeInTheDocument()
  })

  it('does not render a remove button when onRemove is absent', () => {
    render(<ContextFilePill file={makeFile()} />)
    expect(screen.queryByTestId('remove-file-1')).not.toBeInTheDocument()
  })

  it('calls onRemove with the file id when remove is clicked', async () => {
    const onRemove = vi.fn()
    const user = userEvent.setup()
    render(<ContextFilePill file={makeFile()} onRemove={onRemove} />)
    await user.click(screen.getByTestId('remove-file-1'))
    expect(onRemove).toHaveBeenCalledWith('1')
  })
})
