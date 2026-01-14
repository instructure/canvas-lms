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
import CommentEditView from '../CommentEditView'
import {SpeedGraderLegacy_UpdateCommentBankItem} from '../../graphql/mutations'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert')

describe('CommentEditView', () => {
  afterEach(() => {
    cleanup()
  })

  const defaultProps = {
    id: 'comment-1',
    initialValue: 'Initial comment text',
    onClose: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  const createUpdateMock = ({
    id = 'comment-1',
    comment = 'Updated comment text',
    success = true,
  }: {
    id?: string
    comment?: string
    success?: boolean
  } = {}) => ({
    request: {
      query: SpeedGraderLegacy_UpdateCommentBankItem,
      variables: {id, comment},
    },
    result: success
      ? {
          data: {
            updateCommentBankItem: {
              commentBankItem: {
                id,
                comment,
              },
              errors: null,
            },
          },
        }
      : undefined,
    error: success ? undefined : new Error('GraphQL error'),
  })

  const setup = (mocks: any[], props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <CommentEditView {...mergedProps} />
      </MockedProvider>,
    )
  }

  describe('Rendering Tests', () => {
    it('renders textarea with initial value', () => {
      setup([])
      const textarea = screen.getByTestId('comment-library-edit-textarea')
      expect(textarea).toHaveValue('Initial comment text')
    })

    it('renders textarea with correct placeholder', () => {
      setup([])
      expect(screen.getByPlaceholderText('Write something...')).toBeInTheDocument()
    })

    it('renders textarea with screen reader label', () => {
      setup([])
      expect(screen.getByLabelText('Edit comment')).toBeInTheDocument()
    })

    it('renders Cancel button', () => {
      setup([])
      expect(screen.getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    })

    it('renders Save button', () => {
      setup([])
      expect(screen.getByRole('button', {name: 'Save'})).toBeInTheDocument()
    })

    it('Save button is disabled when textarea is empty', async () => {
      const user = userEvent.setup()
      setup([])

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.clear(textarea)

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      expect(saveButton).toBeDisabled()
    })

    it('Save button is disabled when value matches initialValue', () => {
      setup([])
      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      expect(saveButton).toBeDisabled()
    })

    it('Save button is enabled when value is different from initialValue', async () => {
      const user = userEvent.setup()
      setup([])

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' updated')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      expect(saveButton).not.toBeDisabled()
    })
  })

  describe('User Interaction Tests', () => {
    it('textarea autofocuses on mount', () => {
      setup([])
      const textarea = screen.getByTestId('comment-library-edit-textarea')
      expect(textarea).toHaveFocus()
    })

    it('text input updates component state', async () => {
      const user = userEvent.setup()
      setup([])

      const textarea = screen.getByTestId('comment-library-edit-textarea') as HTMLTextAreaElement
      await user.clear(textarea)
      await user.type(textarea, 'New text')

      expect(textarea.value).toBe('New text')
    })

    it('Cancel button calls onClose callback', async () => {
      const user = userEvent.setup()
      const onClose = vi.fn()
      setup([], {onClose})

      const cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      await user.click(cancelButton)

      expect(onClose).toHaveBeenCalledTimes(1)
    })

    it('Save button triggers mutation with correct variables', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text modified'})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' modified')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment updated',
          type: 'success',
        })
      })
    })

    it('textarea value updates when user types', async () => {
      const user = userEvent.setup()
      setup([])

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' and more')

      expect(textarea).toHaveValue('Initial comment text and more')
    })
  })

  describe('GraphQL Mutation Tests', () => {
    it('mutation called with correct id and comment value', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [
        createUpdateMock({
          id: 'comment-123',
          comment: 'Custom initial value updated',
        }),
      ]
      setup(mocks, {id: 'comment-123', initialValue: 'Custom initial value'})

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' updated')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalled()
      })
    })

    it('success flash alert shows "Comment updated"', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text changed'})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' changed')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment updated',
          type: 'success',
        })
      })
    })

    it('onClose is called after successful mutation', async () => {
      const user = userEvent.setup()
      const onClose = vi.fn()
      const mocks = [createUpdateMock({comment: 'Initial comment text modified'})]
      setup(mocks, {onClose})

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' modified')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(onClose).toHaveBeenCalledTimes(1)
      })
    })

    it('button is disabled during mutation execution', async () => {
      const user = userEvent.setup()
      const delayedMock = {
        request: {
          query: SpeedGraderLegacy_UpdateCommentBankItem,
          variables: {id: 'comment-1', comment: 'Initial comment text loading'},
        },
        delay: 100,
        result: {
          data: {
            updateCommentBankItem: {
              commentBankItem: {
                id: 'comment-1',
                comment: 'Initial comment text loading',
              },
              errors: null,
            },
          },
        },
      }

      setup([delayedMock])

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' loading')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      expect(saveButton).not.toBeDisabled()

      await user.click(saveButton)

      await waitFor(() => {
        expect(saveButton).toBeDisabled()
      })

      await waitFor(
        () => {
          expect(saveButton).not.toBeDisabled()
        },
        {timeout: 3000},
      )
    })
  })

  describe('Error Handling Tests', () => {
    it('error flash alert shows "Error updating comment" on mutation failure', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text error', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' error')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error updating comment',
          type: 'error',
        })
      })
    })

    it('text is preserved in textarea on failure', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text preserved', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea') as HTMLTextAreaElement
      await user.type(textarea, ' preserved')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error updating comment',
          type: 'error',
        })
      })

      expect(textarea.value).toBe('Initial comment text preserved')
    })

    it('button re-enables after error', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text retry', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' retry')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error updating comment',
          type: 'error',
        })
      })

      expect(saveButton).not.toBeDisabled()
    })

    it('onClose is not called when mutation fails', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const onClose = vi.fn()
      const mocks = [createUpdateMock({comment: 'Initial comment text fail', success: false})]
      setup(mocks, {onClose})

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' fail')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      await user.click(saveButton)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error updating comment',
          type: 'error',
        })
      })

      expect(onClose).not.toHaveBeenCalled()
    })
  })

  describe('Accessibility Tests', () => {
    it('textarea has screen reader label', () => {
      setup([])
      expect(screen.getByLabelText('Edit comment')).toBeInTheDocument()
    })

    it('Cancel button is keyboard accessible with Enter key', async () => {
      const user = userEvent.setup()
      const onClose = vi.fn()
      setup([], {onClose})

      const cancelButton = screen.getByTestId('comment-library-edit-cancel-button')
      cancelButton.focus()
      await user.keyboard('{Enter}')

      expect(onClose).toHaveBeenCalled()
    })

    it('Save button is keyboard accessible with Enter key', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text keyboard'})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' keyboard')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      saveButton.focus()
      await user.keyboard('{Enter}')

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalled()
      })
    })

    it('Save button is keyboard accessible with Space key', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createUpdateMock({comment: 'Initial comment text space'})]
      setup(mocks)

      const textarea = screen.getByTestId('comment-library-edit-textarea')
      await user.type(textarea, ' space')

      const saveButton = screen.getByTestId('comment-library-edit-save-button')
      saveButton.focus()
      await user.keyboard(' ')

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalled()
      })
    })
  })
})
