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
import {MockedProvider} from '@apollo/client/testing'
import CommentRouterView from '../CommentRouterView'
import {SpeedGraderLegacy_UpdateCommentBankItem} from '../../graphql/mutations'
import * as shave from '@canvas/shave'

vi.mock('@canvas/shave')
vi.mock('@canvas/alerts/react/FlashAlert')

describe('CommentRouterView', () => {
  const defaultProps = {
    id: 'comment-1',
    comment: 'Test comment text',
    index: 0,
    onClick: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    ;(shave.default as any).mockReturnValue(false)
  })

  const createUpdateMock = (comment: string) => ({
    request: {
      query: SpeedGraderLegacy_UpdateCommentBankItem,
      variables: {id: 'comment-1', comment},
    },
    result: {
      data: {
        updateCommentBankItem: {
          commentBankItem: {
            id: 'comment-1',
            comment,
          },
          errors: null,
        },
      },
    },
  })

  const setup = (mocks: any[], props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <CommentRouterView {...mergedProps} />
      </MockedProvider>,
    )
  }

  describe('Routing Tests', () => {
    it('initially renders CommentReadView by default', () => {
      setup([])
      expect(screen.getByText('Test comment text')).toBeInTheDocument()
      expect(screen.queryByTestId('comment-library-edit-textarea')).not.toBeInTheDocument()
    })

    it('switches to CommentEditView when edit button is clicked', async () => {
      const user = userEvent.setup()
      setup([])

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })
      expect(screen.queryByText('Use comment')).not.toBeInTheDocument()
    })

    it('returns to CommentReadView when Cancel button is clicked in edit mode', async () => {
      const user = userEvent.setup()
      setup([])

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      const cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      await user.click(cancelButton)

      await waitFor(() => {
        expect(screen.getByText('Test comment text')).toBeInTheDocument()
      })
      expect(screen.queryByTestId('comment-library-edit-textarea')).not.toBeInTheDocument()
    })

    it('returns to CommentReadView after successful save', async () => {
      const user = userEvent.setup()
      const mocks = [createUpdateMock('Test comment text updated')]
      setup(mocks)

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' updated')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(screen.queryByTestId('comment-library-edit-textarea')).not.toBeInTheDocument()
      })
    })

    it('passes correct id to CommentReadView', () => {
      const {getByTestId} = setup([], {id: 'custom-id-123'})
      expect(getByTestId('comment-library-delete-button-0')).toBeInTheDocument()
    })

    it('passes correct id to CommentEditView', async () => {
      const user = userEvent.setup()
      setup([], {id: 'custom-id-456', comment: 'Custom comment'})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        const textarea = screen.getByTestId('comment-library-edit-textarea')
        expect(textarea).toHaveValue('Custom comment')
      })
    })

    it('passes correct comment to CommentReadView', () => {
      setup([], {comment: 'Specific test comment'})
      expect(screen.getByText('Specific test comment')).toBeInTheDocument()
    })

    it('passes correct initialValue to CommentEditView', async () => {
      const user = userEvent.setup()
      setup([], {comment: 'Initial value test'})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        const textarea = screen.getByTestId('comment-library-edit-textarea')
        expect(textarea).toHaveValue('Initial value test')
      })
    })

    it('passes correct index to CommentReadView', () => {
      const {getByTestId} = setup([], {index: 5})
      expect(getByTestId('comment-library-item-5')).toBeInTheDocument()
    })

    it('passes correct onClick to CommentReadView', async () => {
      const user = userEvent.setup()
      const onClick = vi.fn()
      setup([], {onClick})

      const commentArea = screen.getByText('Test comment text').closest('div')
      await user.click(commentArea!)

      expect(onClick).toHaveBeenCalled()
    })
  })

  describe('State Management Tests', () => {
    it('isEditing state starts as false', () => {
      setup([])
      expect(screen.getByText('Test comment text')).toBeInTheDocument()
      expect(screen.queryByTestId('comment-library-edit-textarea')).not.toBeInTheDocument()
    })

    it('isEditing state updates to true when edit button is clicked', async () => {
      const user = userEvent.setup()
      setup([])

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })
    })

    it('isEditing state updates to false when Cancel is clicked', async () => {
      const user = userEvent.setup()
      setup([])

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      const cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      await user.click(cancelButton)

      await waitFor(() => {
        expect(screen.queryByTestId('comment-library-edit-textarea')).not.toBeInTheDocument()
      })
    })

    it('maintains state correctly through multiple edit/cancel cycles', async () => {
      const user = userEvent.setup()
      setup([])

      // First cycle: edit then cancel
      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      let cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      await user.click(cancelButton)

      await waitFor(() => {
        expect(screen.getByText('Test comment text')).toBeInTheDocument()
      })

      // Second cycle: edit then cancel again
      const editButton2 = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton2)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      await user.click(cancelButton)

      await waitFor(() => {
        expect(screen.getByText('Test comment text')).toBeInTheDocument()
      })
    })
  })

  describe('Integration Tests', () => {
    it('edit button is visible in read view', () => {
      setup([])
      expect(screen.getByRole('button', {name: /Edit comment:/i})).toBeInTheDocument()
    })

    it('delete button is visible in read view', () => {
      const {getByTestId} = setup([])
      expect(getByTestId('comment-library-delete-button-0')).toBeInTheDocument()
    })

    it('edit and delete buttons are not visible in edit view', async () => {
      const user = userEvent.setup()
      const {queryByTestId} = setup([])

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      await waitFor(() => {
        expect(screen.getByTestId('comment-library-edit-textarea')).toBeInTheDocument()
      })

      expect(screen.queryByRole('button', {name: /Edit comment:/i})).not.toBeInTheDocument()
      expect(queryByTestId('comment-library-delete-button-0')).not.toBeInTheDocument()
    })

    it('clicking edit button does not trigger onClick', async () => {
      const user = userEvent.setup()
      const onClick = vi.fn()
      setup([], {onClick})

      const editButton = screen.getByRole('button', {name: /Edit comment:/i})
      await user.click(editButton)

      expect(onClick).not.toHaveBeenCalled()
    })
  })
})
