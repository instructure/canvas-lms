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
import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import {CreateCommentSection} from '../CreateCommentSection'
import {SpeedGraderLegacy_CreateCommentBankItem} from '../../graphql/mutations'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')

describe('CreateCommentSection', () => {
  const defaultProps = {
    courseId: '1',
  }

  const createCommentMock = ({
    courseId = '1',
    comment = 'Test comment text',
    success = true,
  }: {
    courseId?: string
    comment?: string
    success?: boolean
  } = {}) => ({
    request: {
      query: SpeedGraderLegacy_CreateCommentBankItem,
      variables: {courseId, comment},
    },
    result: success
      ? {
          data: {
            createCommentBankItem: {
              commentBankItem: {
                id: 'new-comment-id',
                comment,
              },
              errors: null,
            },
          },
        }
      : undefined,
    error: success ? undefined : new Error('Mutation failed'),
  })

  const setup = (mocks: any[], props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(
      <MockedProvider mocks={mocks} addTypename={true}>
        <CreateCommentSection {...mergedProps} />
      </MockedProvider>,
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Rendering Tests', () => {
    it('renders textarea with correct placeholder and label', () => {
      const mocks: any[] = []
      setup(mocks)

      expect(screen.getByPlaceholderText('Write something...')).toBeInTheDocument()
      expect(screen.getByText('Add comment to library')).toBeInTheDocument()
    })

    it('renders "Add to Library" button', () => {
      const mocks: any[] = []
      setup(mocks)

      expect(screen.getByRole('button', {name: 'Add to Library'})).toBeInTheDocument()
    })

    it('button is disabled when textarea is empty', () => {
      const mocks: any[] = []
      setup(mocks)

      const button = screen.getByRole('button', {name: 'Add to Library'})
      expect(button).toHaveAttribute('disabled')
    })

    it('button is enabled when text is entered', async () => {
      const user = userEvent.setup()
      const mocks: any[] = []
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      expect(button).not.toHaveAttribute('disabled')
    })
  })

  describe('User Interaction Tests', () => {
    it('text input updates component state', async () => {
      const user = userEvent.setup()
      const mocks: any[] = []
      setup(mocks)

      const textarea = screen.getByTestId(
        'create-comment-library-item-textarea',
      ) as HTMLTextAreaElement
      await user.type(textarea, 'My test comment')

      expect(textarea.value).toBe('My test comment')
    })

    it('clicking "Add to Library" calls mutation with correct variables', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createCommentMock({comment: 'Test comment'})]
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment added',
          type: 'success',
        })
      })
    })

    it('textarea clears after successful submission', async () => {
      const user = userEvent.setup()
      const mocks = [createCommentMock({comment: 'Test comment'})]
      setup(mocks)

      const textarea = screen.getByTestId(
        'create-comment-library-item-textarea',
      ) as HTMLTextAreaElement
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(textarea.value).toBe('')
      })
    })

    it('focus returns to textarea after successful submission', async () => {
      const user = userEvent.setup()
      const mocks = [createCommentMock({comment: 'Test comment'})]
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(textarea).toHaveFocus()
      })
    })
  })

  describe('GraphQL Mutation Tests', () => {
    it('mutation called with correct courseId', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createCommentMock({courseId: '42', comment: 'Test comment'})]
      setup(mocks, {courseId: '42'})

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment added',
          type: 'success',
        })
      })
    })

    it('success flash alert shows "Comment added"', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createCommentMock({comment: 'Test comment'})]
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Comment added',
          type: 'success',
        })
      })
    })
  })

  describe('Error Handling Tests', () => {
    it('error flash alert shows "Failed to add comment" on mutation failure', async () => {
      const user = userEvent.setup()
      const showFlashAlertMock = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mocks = [createCommentMock({comment: 'Test comment', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(showFlashAlertMock).toHaveBeenCalledWith({
          message: 'Failed to add comment',
          type: 'error',
        })
      })
    })

    it('text is preserved in textarea on failure', async () => {
      const user = userEvent.setup()
      const mocks = [createCommentMock({comment: 'Test comment', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId(
        'create-comment-library-item-textarea',
      ) as HTMLTextAreaElement
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(jest.spyOn(FlashAlert, 'showFlashAlert')).toHaveBeenCalledWith({
          message: 'Failed to add comment',
          type: 'error',
        })
      })

      expect(textarea.value).toBe('Test comment')
    })

    it('button re-enables after error', async () => {
      const user = userEvent.setup()
      const mocks = [createCommentMock({comment: 'Test comment', success: false})]
      setup(mocks)

      const textarea = screen.getByTestId('create-comment-library-item-textarea')
      await user.type(textarea, 'Test comment')

      const button = screen.getByRole('button', {name: 'Add to Library'})
      await user.click(button)

      await waitFor(() => {
        expect(jest.spyOn(FlashAlert, 'showFlashAlert')).toHaveBeenCalledWith({
          message: 'Failed to add comment',
          type: 'error',
        })
      })

      expect(button).not.toHaveAttribute('disabled')
    })
  })
})
