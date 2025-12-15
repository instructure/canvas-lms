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
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Suggestions from '../Suggestions'

describe('Suggestions', () => {
  const defaultProps = {
    searchResults: [
      {_id: '1', comment: 'Great work!'},
      {_id: '2', comment: 'Needs improvement'},
    ],
    showResults: true,
    setComment: vi.fn(),
    onClose: vi.fn(),
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Visibility behavior', () => {
    it('renders popover when showResults is true', () => {
      const {getByText} = render(<Suggestions {...defaultProps} />)
      expect(getByText('Insert Comment from Library')).toBeInTheDocument()
    })

    it('hides popover when showResults is false', () => {
      const {queryByText} = render(<Suggestions {...defaultProps} showResults={false} />)
      expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
    })

    it('shows anchor element regardless of visibility state', () => {
      const {getByTestId, rerender} = render(<Suggestions {...defaultProps} showResults={true} />)
      expect(getByTestId('comment-suggestions-anchor')).toBeInTheDocument()

      rerender(<Suggestions {...defaultProps} showResults={false} />)
      expect(getByTestId('comment-suggestions-anchor')).toBeInTheDocument()
    })
  })

  describe('User interactions', () => {
    it('calls setComment with correct comment text when suggestion is clicked', async () => {
      const user = userEvent.setup()
      const {getByTestId} = render(<Suggestions {...defaultProps} />)

      await user.click(getByTestId('comment-suggestion-1'))

      expect(defaultProps.setComment).toHaveBeenCalledWith('Great work!')
    })

    it('calls onClose when close button is clicked', async () => {
      const user = userEvent.setup()
      const {getByTestId} = render(<Suggestions {...defaultProps} />)

      await user.click(getByTestId('close-suggestions'))

      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('calls onClose when Escape key is pressed', async () => {
      const user = userEvent.setup()
      const {getByText} = render(<Suggestions {...defaultProps} />)

      const menu = getByText('Insert Comment from Library').closest('[role="menu"]')
      if (menu) {
        await user.type(menu, '{Escape}')
      }

      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('calls onClose on document click', async () => {
      const onClose = vi.fn()
      render(<Suggestions {...defaultProps} onClose={onClose} />)

      // Simulate document click
      const clickEvent = new MouseEvent('click', {bubbles: true})
      document.dispatchEvent(clickEvent)

      await waitFor(() => {
        expect(onClose).toHaveBeenCalled()
      })
    })
  })

  describe('Content rendering', () => {
    it('renders header with Insert Comment from Library text', () => {
      const {getByText} = render(<Suggestions {...defaultProps} />)
      expect(getByText('Insert Comment from Library')).toBeInTheDocument()
    })

    it('renders all suggestions from searchResults array', () => {
      const {getByTestId} = render(<Suggestions {...defaultProps} />)

      expect(getByTestId('comment-suggestion-1')).toBeInTheDocument()
      expect(getByTestId('comment-suggestion-2')).toBeInTheDocument()
    })

    it('uses correct test IDs for each suggestion item', () => {
      const {getByTestId} = render(<Suggestions {...defaultProps} />)

      const suggestion1 = getByTestId('comment-suggestion-1')
      const suggestion2 = getByTestId('comment-suggestion-2')

      expect(suggestion1).toHaveTextContent('Great work!')
      expect(suggestion2).toHaveTextContent('Needs improvement')
    })
  })

  describe('Multiple suggestions', () => {
    it('renders multiple suggestions correctly with 5 items', () => {
      const searchResults = [
        {_id: '1', comment: 'Comment 1'},
        {_id: '2', comment: 'Comment 2'},
        {_id: '3', comment: 'Comment 3'},
        {_id: '4', comment: 'Comment 4'},
        {_id: '5', comment: 'Comment 5'},
      ]

      const {getByTestId} = render(<Suggestions {...defaultProps} searchResults={searchResults} />)

      searchResults.forEach(result => {
        expect(getByTestId(`comment-suggestion-${result._id}`)).toHaveTextContent(result.comment)
      })
    })

    it('handles empty searchResults array gracefully', () => {
      const {queryByText} = render(<Suggestions {...defaultProps} searchResults={[]} />)

      // Header should still render
      expect(queryByText('Insert Comment from Library')).toBeInTheDocument()
    })
  })

  describe('Long comment truncation', () => {
    it('renders truncation container with correct styles', () => {
      const {getAllByTestId} = render(<Suggestions {...defaultProps} />)

      const truncateContainers = getAllByTestId('truncate-container')
      expect(truncateContainers.length).toBeGreaterThan(0)

      const firstContainer = truncateContainers[0] as HTMLElement
      expect(firstContainer).toHaveStyle({width: '100%', minHeight: '20px'})
    })

    it('handles very long comments', () => {
      const longComment =
        'This is a very long comment that should be truncated. '.repeat(10) +
        'It contains way more text than can fit in three lines and should demonstrate the truncation behavior properly.'

      const searchResults = [{_id: '1', comment: longComment}]

      const {getByTestId} = render(<Suggestions {...defaultProps} searchResults={searchResults} />)

      expect(getByTestId('comment-suggestion-1')).toBeInTheDocument()
    })
  })
})
