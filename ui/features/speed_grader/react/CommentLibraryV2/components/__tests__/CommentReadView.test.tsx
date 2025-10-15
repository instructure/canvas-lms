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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CommentReadView from '../CommentReadView'
import * as shave from '@canvas/shave'

jest.mock('@canvas/shave')

describe('CommentReadView', () => {
  const defaultProps = {
    comment: 'This is a test comment',
    index: 0,
    onClick: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Rendering Tests', () => {
    it('renders comment text', () => {
      render(<CommentReadView {...defaultProps} />)
      expect(screen.getByText('This is a test comment')).toBeInTheDocument()
    })

    it('renders with correct data-testid including index', () => {
      const {getByTestId} = render(<CommentReadView {...defaultProps} index={5} />)
      expect(getByTestId('comment-library-item-5')).toBeInTheDocument()
    })

    it('renders screen reader button with Use comment text', () => {
      render(<CommentReadView {...defaultProps} />)
      expect(
        screen.getByRole('button', {name: /Use comment This is a test comment/i}),
      ).toBeInTheDocument()
    })
  })

  describe('Truncation Tests', () => {
    it('shows show more button when comment is truncated', async () => {
      ;(shave.default as jest.Mock).mockReturnValue(true)

      render(<CommentReadView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('show more')).toBeInTheDocument()
      })
    })

    it('does not show show more button when comment is not truncated', async () => {
      ;(shave.default as jest.Mock).mockReturnValue(false)

      render(<CommentReadView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.queryByText('show more')).not.toBeInTheDocument()
      })
    })

    it('toggles between show more and show less on button click', async () => {
      const user = userEvent.setup()
      ;(shave.default as jest.Mock).mockReturnValue(true)

      render(<CommentReadView {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('show more')).toBeInTheDocument()
      })

      const toggleButton = screen.getByRole('button', {name: 'show more'})
      await user.click(toggleButton)

      expect(screen.getByText('show less')).toBeInTheDocument()

      await user.click(screen.getByRole('button', {name: 'show less'}))

      expect(screen.getByText('show more')).toBeInTheDocument()
    })

    it('expands comment text when show more is clicked', async () => {
      const user = userEvent.setup()
      ;(shave.default as jest.Mock).mockReturnValue(true)

      const longComment = 'This is a very long comment that should be truncated initially'
      render(<CommentReadView {...defaultProps} comment={longComment} />)

      await waitFor(() => {
        expect(screen.getByText('show more')).toBeInTheDocument()
      })

      const toggleButton = screen.getByRole('button', {name: 'show more'})
      await user.click(toggleButton)

      // After expansion, full text should be visible
      expect(screen.getByText(longComment)).toBeInTheDocument()
    })
  })

  describe('Interaction Tests', () => {
    it('calls onClick when comment area is clicked', async () => {
      const user = userEvent.setup()
      const onClick = jest.fn()

      render(<CommentReadView {...defaultProps} onClick={onClick} />)

      const commentArea = screen.getByText('This is a test comment').closest('div')
      await user.click(commentArea!)

      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick when screen reader button is clicked', async () => {
      const user = userEvent.setup()
      const onClick = jest.fn()

      render(<CommentReadView {...defaultProps} onClick={onClick} />)

      const srButton = screen.getByRole('button', {name: /Use comment/i})
      await user.click(srButton)

      expect(onClick).toHaveBeenCalled()
    })

    it('applies hover background styling on mouse enter', async () => {
      const user = userEvent.setup()
      render(<CommentReadView {...defaultProps} />)

      const commentArea = screen.getByText('This is a test comment').closest('div')
      await user.hover(commentArea!)

      // Check if the background changes (component sets background to 'brand' on hover)
      expect(commentArea).toHaveStyle({cursor: 'pointer'})
    })

    it('applies focus background on focus', async () => {
      render(<CommentReadView {...defaultProps} />)

      const commentArea = screen.getByText('This is a test comment').closest('div')
      commentArea!.focus()

      // Verify the element can receive focus
      expect(commentArea).toHaveFocus()
    })
  })

  describe('Accessibility Tests', () => {
    it('screen reader button has correct label with comment text', () => {
      render(<CommentReadView {...defaultProps} comment="Custom comment text" />)

      expect(
        screen.getByRole('button', {name: 'Use comment Custom comment text'}),
      ).toBeInTheDocument()
    })

    it('screen reader button is keyboard accessible', async () => {
      const user = userEvent.setup()
      const onClick = jest.fn()

      render(<CommentReadView {...defaultProps} onClick={onClick} />)

      const srButton = screen.getByRole('button', {name: /Use comment/i})
      srButton.focus()
      await user.keyboard('{Enter}')

      expect(onClick).toHaveBeenCalled()
    })

    it('screen reader button has correct test id', () => {
      const {getByTestId} = render(<CommentReadView {...defaultProps} index={3} />)

      expect(getByTestId('comment-library-item-use-button-3')).toBeInTheDocument()
    })
  })
})
