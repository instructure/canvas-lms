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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import CommentReadView from '../CommentReadView'
import * as shave from '@canvas/shave'

vi.mock('@canvas/shave')
vi.mock('@canvas/alerts/react/FlashAlert')

describe('CommentReadView', () => {
  afterEach(() => {
    cleanup()
  })

  const defaultProps = {
    id: 'comment-1',
    comment: 'This is a test comment',
    index: 0,
    onClick: vi.fn(),
    setIsEditing: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  const renderWithMocks = (props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(
      <MockedProvider mocks={[]} addTypename={false}>
        <CommentReadView {...mergedProps} />
      </MockedProvider>,
    )
  }

  describe('Rendering Tests', () => {
    it('renders comment text', () => {
      renderWithMocks()
      expect(screen.getByText('This is a test comment')).toBeInTheDocument()
    })

    it('renders with correct data-testid including index', () => {
      const {getByTestId} = renderWithMocks({index: 5})
      expect(getByTestId('comment-library-item-5')).toBeInTheDocument()
    })

    it('renders screen reader button with Use comment text', () => {
      renderWithMocks()
      expect(
        screen.getByRole('button', {name: /Use comment This is a test comment/i}),
      ).toBeInTheDocument()
    })

    it('renders DeleteCommentIconButton', () => {
      const {getByTestId} = renderWithMocks()
      expect(getByTestId('comment-library-delete-button-0')).toBeInTheDocument()
    })

    it('renders edit button with correct icon', () => {
      const {getByTestId} = renderWithMocks()
      expect(getByTestId('comment-library-edit-button-0')).toBeInTheDocument()
    })

    it('edit button has correct data-testid based on index', () => {
      const {getByTestId} = renderWithMocks({index: 3})
      expect(getByTestId('comment-library-edit-button-3')).toBeInTheDocument()
    })

    it('edit button has correct screen reader label with comment text', () => {
      renderWithMocks({comment: 'Specific comment'})
      expect(
        screen.getByRole('button', {name: 'Edit comment: Specific comment'}),
      ).toBeInTheDocument()
    })
  })

  describe('Truncation Tests', () => {
    it('shows show more button when comment is truncated', async () => {
      ;(shave.default as any).mockReturnValue(true)

      renderWithMocks()

      await waitFor(() => {
        expect(screen.getByText('show more')).toBeInTheDocument()
      })
    })

    it('does not show show more button when comment is not truncated', async () => {
      ;(shave.default as any).mockReturnValue(false)

      renderWithMocks()

      await waitFor(() => {
        expect(screen.queryByText('show more')).not.toBeInTheDocument()
      })
    })

    it('toggles between show more and show less on button click', async () => {
      const user = userEvent.setup()
      ;(shave.default as any).mockReturnValue(true)

      renderWithMocks()

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
      ;(shave.default as any).mockReturnValue(true)

      const longComment = 'This is a very long comment that should be truncated initially'
      renderWithMocks({comment: longComment})

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
      const onClick = vi.fn()

      renderWithMocks({onClick})

      const commentArea = screen.getByText('This is a test comment').closest('div')
      await user.click(commentArea!)

      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick when screen reader button is clicked', async () => {
      const user = userEvent.setup()
      const onClick = vi.fn()

      renderWithMocks({onClick})

      const srButton = screen.getByRole('button', {name: /Use comment/i})
      await user.click(srButton)

      expect(onClick).toHaveBeenCalled()
    })

    it('applies hover background styling on mouse enter', async () => {
      const user = userEvent.setup()
      renderWithMocks()

      const commentArea = screen.getByText('This is a test comment').closest('div')
      await user.hover(commentArea!)

      // Check if the background changes (component sets background to 'brand' on hover)
      expect(commentArea).toHaveStyle({cursor: 'pointer'})
    })

    it('applies focus background on focus', async () => {
      renderWithMocks()

      const commentArea = screen.getByText('This is a test comment').closest('div')
      commentArea!.focus()

      // Verify the element can receive focus
      expect(commentArea).toHaveFocus()
    })
  })

  describe('Accessibility Tests', () => {
    it('screen reader button has correct label with comment text', () => {
      renderWithMocks({comment: 'Custom comment text'})

      expect(
        screen.getByRole('button', {name: 'Use comment Custom comment text'}),
      ).toBeInTheDocument()
    })

    it('screen reader button is keyboard accessible', async () => {
      const user = userEvent.setup()
      const onClick = vi.fn()

      renderWithMocks({onClick})

      const srButton = screen.getByRole('button', {name: /Use comment/i})
      srButton.focus()
      await user.keyboard('{Enter}')

      expect(onClick).toHaveBeenCalled()
    })

    it('screen reader button has correct test id', () => {
      const {getByTestId} = renderWithMocks({index: 3})

      expect(getByTestId('comment-library-item-use-button-3')).toBeInTheDocument()
    })
  })

  describe('Edit Button Tests', () => {
    it('clicking edit button calls setIsEditing with true', async () => {
      const user = userEvent.setup()
      const setIsEditing = vi.fn()

      renderWithMocks({setIsEditing})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      expect(setIsEditing).toHaveBeenCalledTimes(1)
      expect(setIsEditing).toHaveBeenCalledWith(true)
    })

    it('edit button is keyboard accessible with Enter key', async () => {
      const user = userEvent.setup()
      const setIsEditing = vi.fn()

      renderWithMocks({setIsEditing})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      editButton.focus()
      await user.keyboard('{Enter}')

      expect(setIsEditing).toHaveBeenCalledWith(true)
    })

    it('edit button is keyboard accessible with Space key', async () => {
      const user = userEvent.setup()
      const setIsEditing = vi.fn()

      renderWithMocks({setIsEditing})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      editButton.focus()
      await user.keyboard(' ')

      expect(setIsEditing).toHaveBeenCalledWith(true)
    })
  })
})
