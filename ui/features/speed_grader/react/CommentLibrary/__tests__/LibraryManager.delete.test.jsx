/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {vi} from 'vitest'
import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {act, cleanup, fireEvent, render as rtlRender, waitFor} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {commentBankItemMocks, makeDeleteCommentMutation} from './mocks'
import {DELETE_COMMENT_MUTATION} from '../graphql/Mutations'
import LibraryManager from '../LibraryManager'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.useFakeTimers()

describe('LibraryManager - delete', () => {
  let setFocusToTextAreaMock
  const oldWindowConfirm = window.confirm

  const defaultProps = (props = {}) => {
    return {
      setComment: () => {},
      courseId: '1',
      setFocusToTextArea: setFocusToTextAreaMock,
      userId: '1',
      commentAreaText: '',
      suggestionsRef: document.body,
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = {comment_library_suggestions_enabled: true}
    setFocusToTextAreaMock = vi.fn()
    window.confirm = vi.fn()
    window.confirm.mockImplementation(() => true)
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
    window.confirm = oldWindowConfirm
    window.ENV = {}
  })

  const render = ({
    props = defaultProps(),
    mocks = commentBankItemMocks({numberOfComments: 10}),
    func = rtlRender,
  } = {}) =>
    func(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <LibraryManager {...props} />
      </MockedProvider>,
    )

  it('deletes the comment and removes the comment from the tray when the trash button is clicked', async () => {
    const mutationMock = await makeDeleteCommentMutation({
      overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
      variables: {id: '0'},
    })
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText, queryByText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))

    fireEvent.click(getByText('Delete comment: Comment item 0'))
    await waitFor(() => {
      expect(queryByText('Comment item 0')).not.toBeInTheDocument()
    })
  })

  it('displays an error if the delete mutation failed', async () => {
    const errorMock = {
      request: {
        query: DELETE_COMMENT_MUTATION,
        variables: {id: '0'},
      },
      error: new Error('Delete failed'),
    }
    const mocks = [...commentBankItemMocks(), errorMock]
    const {getByText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    fireEvent.click(getByText('Delete comment: Comment item 0'))

    await waitFor(() => {
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Error deleting comment',
        type: 'error',
      })
    })
  })

  it('does not delete if the user rejects the confirmation prompt', async () => {
    window.confirm.mockImplementation(() => false)
    const mutationMock = await makeDeleteCommentMutation({
      overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
      variables: {id: '0'},
    })
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))

    fireEvent.click(getByText('Delete comment: Comment item 0'))
    await act(async () => vi.advanceTimersByTime(1000))
    expect(getByText('Delete comment: Comment item 0')).toBeInTheDocument()
  })

  it("focuses on the previous comment's trash icon after deleting", async () => {
    const mutationMock = await makeDeleteCommentMutation({
      overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '1'}},
      variables: {id: '1'},
    })
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))

    fireEvent.click(getByText('Delete comment: Comment item 1'))
    await waitFor(() => {
      expect(getByText('Delete comment: Comment item 0').closest('button')).toHaveFocus()
    })
  })

  it('focuses on the close tray button if the last comment was deleted', async () => {
    const mutationMock = await makeDeleteCommentMutation({
      overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
      variables: {id: '0'},
    })
    const mocks = [...commentBankItemMocks({numberOfComments: 1}), ...mutationMock]
    const {getByText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    fireEvent.click(getByText('Delete comment: Comment item 0'))
    await waitFor(() => {
      expect(getByText('Close comment library').closest('button')).toHaveFocus()
    })
  })
})
