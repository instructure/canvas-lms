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
import DeleteCommentIconButton from '../DeleteCommentIconButton'
import {SpeedGraderLegacy_DeleteCommentBankItem} from '../../graphql/mutations'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {type MockInstance} from 'vitest'

vi.mock('@canvas/alerts/react/FlashAlert')

describe('DeleteCommentIconButton', () => {
  const defaultProps = {
    id: 'comment-1',
    comment: 'This is a test comment',
    index: 0,
  }

  let confirmSpy: MockInstance

  beforeEach(() => {
    vi.clearAllMocks()
    confirmSpy = vi.spyOn(window, 'confirm')
  })

  afterEach(() => {
    confirmSpy.mockRestore()
  })

  const createDeleteMock = (success = true) => ({
    request: {
      query: SpeedGraderLegacy_DeleteCommentBankItem,
      variables: {id: 'comment-1'},
    },
    result: success
      ? {
          data: {
            deleteCommentBankItem: {
              commentBankItemId: 'comment-1',
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
        <DeleteCommentIconButton {...mergedProps} />
      </MockedProvider>,
    )
  }

  describe('Rendering Tests', () => {
    it('renders delete icon button', () => {
      setup([])
      const button = screen.getByRole('button', {name: /Delete comment:/i})
      expect(button).toBeInTheDocument()
    })

    it('has correct data-testid based on index', () => {
      const {getByTestId} = setup([], {index: 5})
      expect(getByTestId('comment-library-delete-button-5')).toBeInTheDocument()
    })

    it('has correct screen reader label with comment text', () => {
      setup([], {comment: 'Custom comment text'})
      expect(
        screen.getByRole('button', {name: 'Delete comment: Custom comment text'}),
      ).toBeInTheDocument()
    })

    it('renders with IconTrashLine icon', () => {
      setup([])
      const button = screen.getByRole('button', {name: /Delete comment:/i})
      expect(button.querySelector('svg')).toBeInTheDocument()
    })
  })

  describe('Interaction Tests', () => {
    it('shows window.confirm dialog when button is clicked', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(false)
      setup([])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      expect(confirmSpy).toHaveBeenCalledWith('Are you sure you want to delete this comment?')
    })

    it('does not trigger mutation when deletion is canceled', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(false)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock()])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      expect(confirmSpy).toHaveBeenCalled()
      expect(showFlashAlertMock).not.toHaveBeenCalled()
    })

    it('triggers mutation when deletion is confirmed', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock()])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment deleted',
          type: 'success',
        })
      })
    })

    it('button is disabled during mutation execution', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)

      const delayedMock = {
        request: {
          query: SpeedGraderLegacy_DeleteCommentBankItem,
          variables: {id: 'comment-1'},
        },
        delay: 100,
        result: {
          data: {
            deleteCommentBankItem: {
              commentBankItemId: 'comment-1',
              errors: null,
            },
          },
        },
      }

      setup([delayedMock])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      expect(button).not.toBeDisabled()

      await user.click(button)

      // Button should be disabled during mutation
      await waitFor(() => {
        expect(button).toBeDisabled()
      })

      // Wait for mutation to complete
      await waitFor(
        () => {
          expect(button).not.toBeDisabled()
        },
        {timeout: 3000},
      )
    })
  })

  describe('GraphQL Mutation Tests', () => {
    it('mutation is called with correct ID', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)

      const customMock = {
        request: {
          query: SpeedGraderLegacy_DeleteCommentBankItem,
          variables: {id: 'comment-123'},
        },
        result: {
          data: {
            deleteCommentBankItem: {
              commentBankItemId: 'comment-123',
              errors: null,
            },
          },
        },
      }

      setup([customMock], {id: 'comment-123'})

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      await waitFor(() => {
        expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
      })
    })

    it('shows success flash alert on successful deletion', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock(true)])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment deleted',
          type: 'success',
        })
      })
    })

    it('shows error flash alert on failed deletion', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock(false)])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Error deleting comment',
          type: 'error',
        })
      })
    })
  })

  describe('Accessibility Tests', () => {
    it('screen reader label includes comment text', () => {
      setup([], {comment: 'Specific comment for testing'})

      expect(
        screen.getByRole('button', {name: 'Delete comment: Specific comment for testing'}),
      ).toBeInTheDocument()
    })

    it('button is keyboard accessible with Enter key', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock()])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      button.focus()
      await user.keyboard('{Enter}')

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalled()
      })
    })

    it('button is keyboard accessible with Space key', async () => {
      const user = userEvent.setup()
      confirmSpy.mockReturnValue(true)
      const showFlashAlertMock = vi.spyOn(FlashAlert, 'showFlashAlert')

      setup([createDeleteMock()])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      button.focus()
      await user.keyboard(' ')

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalled()
      })
    })

    it('button is enabled before user interaction', () => {
      setup([createDeleteMock()])

      const button = screen.getByRole('button', {name: /Delete comment:/i})
      expect(button).not.toBeDisabled()
    })
  })
})
