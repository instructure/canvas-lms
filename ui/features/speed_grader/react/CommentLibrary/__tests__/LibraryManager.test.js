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

import React from 'react'
import {MockedProvider} from '@apollo/react-testing'
import {act, fireEvent, render as rtlRender, waitFor} from '@testing-library/react'
import {createCache} from '@canvas/apollo'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {commentBankItemMocks, makeDeleteCommentMutation, makeCreateMutationMock} from './mocks'
import LibraryManager from '../LibraryManager'

jest.useFakeTimers()

describe('LibraryManager', () => {
  const inputRef = document.createElement('input')
  const defaultProps = (props = {}) => {
    return {
      setComment: () => {},
      courseId: '1',
      textAreaRef: {current: inputRef},
      userId: '1',
      ...props
    }
  }

  const render = ({
    props = defaultProps(),
    mocks = commentBankItemMocks({numberOfComments: 10})
  } = {}) =>
    rtlRender(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <LibraryManager {...props} />
      </MockedProvider>
    )

  describe('query', () => {
    it('renders a loading spinner while loading', () => {
      const {getByText} = render(defaultProps())
      expect(getByText('Loading comment library')).toBeInTheDocument()
    })

    it('displays an error if the comments couldnt be fetched', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      render({mocks: []})
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error loading comment library',
        type: 'error'
      })
    })

    it('calls focus on textAreaRef.current when a comment within the tray is clicked', async () => {
      const {getByText} = render()
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      fireEvent.click(getByText('Comment item 0'))
      expect(document.activeElement).toBe(inputRef)
    })
  })

  describe('create', () => {
    const variables = {comment: 'test comment', courseId: '1'}
    const overrides = {CommentBankItem: {comment: 'test comment'}}

    it('creates the comment and loads it when the "Add comment" button is clicked', async () => {
      const mutationMock = await makeCreateMutationMock({variables, overrides})
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, getByLabelText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      expect(getByText('test comment')).toBeInTheDocument()
    })

    it('disables the "Add comment" button while a comment is being added to the library', async () => {
      const mutationMock = await makeCreateMutationMock({variables, overrides})
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, getByLabelText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      expect(getByText('Adding to Library').closest('button')).toBeDisabled()
    })

    it('displays an error if the create mutation failed', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {getByText, getByLabelText} = render()
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error creating comment',
        type: 'error'
      })
    })
  })

  describe('delete', () => {
    const oldWindowConfirm = window.confirm

    beforeEach(() => {
      window.confirm = jest.fn()
      window.confirm.mockImplementation(() => true)
    })

    afterEach(() => {
      window.confirm = oldWindowConfirm
    })

    it('deletes the comment and removes the comment from the tray when the trash button is clicked', async () => {
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
        variables: {id: '0'}
      })
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, queryByText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))

      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await act(async () => jest.runAllTimers())
      expect(queryByText('Comment item 0')).not.toBeInTheDocument()
    })

    it('displays an error if the delete mutation failed', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {getByText} = render()
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      fireEvent.click(getByText('Delete comment: Comment item 0'))

      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error deleting comment',
        type: 'error'
      })
    })

    it('does not delete if the user rejects the confirmation prompt', async () => {
      window.confirm.mockImplementation(() => false)
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
        variables: {id: '0'}
      })
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))

      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await act(async () => jest.runAllTimers())
      expect(getByText('Delete comment: Comment item 0')).toBeInTheDocument()
    })

    it("focuses on the previous comment's trash icon after deleting", async () => {
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '1'}},
        variables: {id: '1'}
      })
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))

      fireEvent.click(getByText('Delete comment: Comment item 1'))
      await act(async () => jest.runAllTimers())
      expect(getByText('Delete comment: Comment item 0').closest('button')).toHaveFocus()
    })

    it('focuses on the close tray button if the last comment was deleted', async () => {
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
        variables: {id: '0'}
      })
      const mocks = [...commentBankItemMocks({numberOfComments: 1}), ...mutationMock]
      const {getByText} = render({mocks})
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Open Comment Tray'))
      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await waitFor(() => {
        expect(getByText('Close comment library').closest('button')).toHaveFocus()
      })
    })
  })
})
