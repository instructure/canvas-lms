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
import UrlSubmissionDisplay from '../UrlSubmissionDisplay'

describe('UrlSubmissionDisplay', () => {
  const mockWindowOpen = vi.fn()

  beforeEach(() => {
    window.open = mockWindowOpen
    mockWindowOpen.mockClear()
  })

  it('renders the URL text', () => {
    const url = 'https://example.com'
    render(<UrlSubmissionDisplay url={url} />)

    expect(screen.getByTestId('url-submission-text')).toHaveTextContent(url)
  })

  it('opens the URL in a new window when clicked', async () => {
    const user = userEvent.setup()
    const url = 'https://example.com/test-page'
    render(<UrlSubmissionDisplay url={url} />)

    const link = screen.getByTestId('url-submission-text')
    await user.click(link)

    expect(mockWindowOpen).toHaveBeenCalledWith(url)
  })

  it('renders the link component', () => {
    const url = 'https://example.com'
    render(<UrlSubmissionDisplay url={url} />)

    const urlText = screen.getByTestId('url-submission-text')
    expect(urlText).toBeInTheDocument()
    expect(urlText.parentElement).toBeTruthy()
  })

  it('handles long URLs', () => {
    const longUrl = 'https://example.com/very/long/path/that/might/wrap/to/multiple/lines'
    render(<UrlSubmissionDisplay url={longUrl} />)

    expect(screen.getByTestId('url-submission-text')).toHaveTextContent(longUrl)
  })

  it('handles URLs with query parameters', () => {
    const url = 'https://example.com/page?param1=value1&param2=value2'
    render(<UrlSubmissionDisplay url={url} />)

    expect(screen.getByTestId('url-submission-text')).toHaveTextContent(url)
  })
})
