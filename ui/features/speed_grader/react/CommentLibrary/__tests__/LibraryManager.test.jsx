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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  commentBankItemMocks,
  makeDeleteCommentMutation,
  makeCreateMutationMock,
  searchMocks,
  makeUpdateMutationMock,
} from './mocks'
import LibraryManager from '../LibraryManager'

jest.useFakeTimers()
jest.mock('@canvas/do-fetch-api-effect')

describe('LibraryManager', () => {
  let setFocusToTextAreaMock
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
    setFocusToTextAreaMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  afterAll(() => {
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
      </MockedProvider>
    )

  describe('query', () => {
    it('renders a loading spinner while loading', () => {
      const {getByText} = render(defaultProps())
      expect(getByText('Loading comment library')).toBeInTheDocument()
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays an error if the comments couldnt be fetched', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      render({mocks: []})
      await act(async () => jest.advanceTimersByTime(1000))
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error loading comment library',
        type: 'error',
      })
    })

    it('calls focus when a comment within the tray is clicked', async () => {
      const {getByText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'), {detail: 1})
      fireEvent.click(getByText('Comment item 0'), {detail: 1})
      expect(setFocusToTextAreaMock).toHaveBeenCalled()
    })
  })

  describe('create', () => {
    const variables = {comment: 'test comment', courseId: '1'}
    const overrides = {CommentBankItem: {comment: 'test comment'}}

    it('creates the comment and loads it when the "Add comment" button is clicked', async () => {
      const mutationMock = await makeCreateMutationMock({variables, overrides})
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, getByLabelText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      expect(getByText('test comment')).toBeInTheDocument()
    })

    it('disables the "Add comment" button while a comment is being added to the library', async () => {
      const mutationMock = await makeCreateMutationMock({variables, overrides})
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, getByLabelText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      expect(getByText('Adding to Library').closest('button')).toBeDisabled()
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays an error if the create mutation failed', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {getByText, getByLabelText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      const input = getByLabelText('Add comment to library')
      fireEvent.change(input, {target: {value: 'test comment'}})
      fireEvent.click(getByText('Add to Library'))
      await act(async () => jest.advanceTimersByTime(1000))
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error creating comment',
        type: 'error',
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
        variables: {id: '0'},
      })
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, queryByText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))

      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await act(async () => jest.advanceTimersByTime(1000))
      expect(queryByText('Comment item 0')).not.toBeInTheDocument()
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays an error if the delete mutation failed', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {getByText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      fireEvent.click(getByText('Delete comment: Comment item 0'))

      await act(async () => jest.advanceTimersByTime(1000))
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error deleting comment',
        type: 'error',
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
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))

      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await act(async () => jest.advanceTimersByTime(1000))
      expect(getByText('Delete comment: Comment item 0')).toBeInTheDocument()
    })

    it("focuses on the previous comment's trash icon after deleting", async () => {
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '1'}},
        variables: {id: '1'},
      })
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))

      fireEvent.click(getByText('Delete comment: Comment item 1'))
      await act(async () => jest.advanceTimersByTime(1000))
      expect(getByText('Delete comment: Comment item 0').closest('button')).toHaveFocus()
    })

    it('focuses on the close tray button if the last comment was deleted', async () => {
      const mutationMock = await makeDeleteCommentMutation({
        overrides: {DeleteCommentBankItemPayload: {commentBankItemId: '0'}},
        variables: {id: '0'},
      })
      const mocks = [...commentBankItemMocks({numberOfComments: 1}), ...mutationMock]
      const {getByText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      fireEvent.click(getByText('Delete comment: Comment item 0'))
      await waitFor(() => {
        expect(getByText('Close comment library').closest('button')).toHaveFocus()
      })
    })
  })

  describe('search', () => {
    it('loads search results when commentAreaText is provided', async () => {
      const mocks = [...commentBankItemMocks(), ...searchMocks()]
      const {getByText} = render({
        props: defaultProps({commentAreaText: 'search'}),
        mocks,
      })

      await act(async () => jest.advanceTimersByTime(1000))
      expect(getByText('search result 0')).toBeInTheDocument()
    })

    it('only loads results when the entered comment is 3 or more characters', async () => {
      const mocks = [...commentBankItemMocks(), ...searchMocks({query: 'se'})]
      const {queryByText} = render({
        props: defaultProps({commentAreaText: 'se'}),
        mocks,
      })
      await act(async () => jest.advanceTimersByTime(1000))
      expect(queryByText('search result 0')).not.toBeInTheDocument()
    })

    it('debounces the commentAreaText when displaying results', async () => {
      const mocks = [...commentBankItemMocks(), ...searchMocks()]
      const {getByText, queryByText} = render({
        props: defaultProps({commentAreaText: 'search'}),
        mocks,
      })

      await act(async () => jest.advanceTimersByTime(50))
      expect(queryByText('search result 0')).not.toBeInTheDocument()
      await act(async () => jest.advanceTimersByTime(1000))
      expect(getByText('search result 0')).toBeInTheDocument()
    })

    it('doesnt rerender the suggestions after clicking on a suggested comment', async () => {
      const mocks = [
        ...commentBankItemMocks(),
        ...searchMocks({query: 'search'}),
        ...searchMocks({query: 'search results 0', maxResults: 1}),
      ]
      const props = defaultProps({commentAreaText: 'search'})
      const {getByText, queryByText, rerender} = render({props, mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('search result 0'))
      await act(async () => jest.advanceTimersByTime(1000))

      render({
        props: defaultProps({commentAreaText: 'search result 0'}),
        mocks,
        func: rerender,
      })
      await act(async () => jest.advanceTimersByTime(1000))
      expect(queryByText('search result 0')).not.toBeInTheDocument()
    })

    it('renders the suggestions as enabled if comment_library_suggestions_enabled is true', async () => {
      const {getByText, getByLabelText} = render({mocks: commentBankItemMocks()})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      expect(getByLabelText('Show suggestions when typing')).toBeChecked()
    })

    it('renders the suggestions as disabled if comment_library_suggestions_enabled is false', async () => {
      window.ENV = {comment_library_suggestions_enabled: false}
      const {getByText, getByLabelText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      expect(getByLabelText('Show suggestions when typing')).not.toBeChecked()
    })

    it("fires a request to save the checkbox state when it's clicked", async () => {
      doFetchApi.mockImplementationOnce(() =>
        Promise.resolve({json: {comment_library_suggestions_enabled: false}})
      )
      const {getByText, getByLabelText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      fireEvent.click(getByLabelText('Show suggestions when typing'))
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'PUT',
        path: '/api/v1/users/self/settings',
        body: {
          comment_library_suggestions_enabled: false,
        },
      })
      expect(getByLabelText('Show suggestions when typing')).not.toBeChecked()
      await act(async () => jest.advanceTimersByTime(1000))
      expect(ENV.comment_library_suggestions_enabled).toBe(false)
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('does not write to ENV if the request fails', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      doFetchApi.mockImplementationOnce(() => Promise.reject(new Error('Network error')))
      const {getByText, getByLabelText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      fireEvent.click(getByLabelText('Show suggestions when typing'))
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      await act(async () => jest.advanceTimersByTime(1000))
      expect(ENV.comment_library_suggestions_enabled).toBe(true)
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error saving suggestion preference',
        type: 'error',
      })
    })
  })

  describe('update', () => {
    const variables = {comment: 'updated comment!', id: '0'}
    const overrides = {CommentBankItem: {comment: 'updated comment!'}}

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('updates the comment and rerenders', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const mutationMock = await makeUpdateMutationMock({variables, overrides})
      const mocks = [...commentBankItemMocks(), ...mutationMock]
      const {getByText, getByLabelText} = render({mocks})
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))

      fireEvent.click(getByText('Edit comment: Comment item 0'))
      const input = getByLabelText('Edit comment')
      fireEvent.change(input, {target: {value: 'updated comment!'}})
      fireEvent.click(getByText('Save'))
      expect(getByText('updated comment!')).toBeInTheDocument()
      await act(async () => jest.advanceTimersByTime(1000))
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Comment updated',
        type: 'success',
      })
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('displays an error if the update mutation failed', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {getByText, getByLabelText} = render()
      await act(async () => jest.advanceTimersByTime(1000))
      fireEvent.click(getByText('Open Comment Library'))
      fireEvent.click(getByText('Edit comment: Comment item 0'))
      const input = getByLabelText('Edit comment')
      fireEvent.change(input, {target: {value: 'not mocked!'}})
      fireEvent.click(getByText('Save'))
      await act(async () => jest.advanceTimersByTime(1000))
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error updating comment',
        type: 'error',
      })
    })
  })
})
