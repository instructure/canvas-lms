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
import {commentBankItemMocks, makeUpdateMutationMock} from './mocks'
import {UPDATE_COMMENT_MUTATION} from '../graphql/Mutations'
import LibraryManager from '../LibraryManager'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

describe('LibraryManager - update', () => {
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
    vi.useFakeTimers()
    fakeEnv.setup({comment_library_suggestions_enabled: true})
    setFocusToTextAreaMock = vi.fn()
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
    vi.useRealTimers()
    fakeEnv.teardown()
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

  const variables = {comment: 'updated comment!', id: '0'}
  const overrides = {CommentBankItem: {comment: 'updated comment!'}}

  it('updates the comment and rerenders', async () => {
    const mutationMock = await makeUpdateMutationMock({variables, overrides})
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText, getByLabelText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))

    fireEvent.click(getByText('Edit comment: Comment item 0'))
    const input = getByLabelText('Edit comment')
    fireEvent.change(input, {target: {value: 'updated comment!'}})
    fireEvent.click(getByText('Save'))
    await waitFor(() => expect(getByText('updated comment!')).toBeInTheDocument(), {
      advanceTimers: vi.advanceTimersByTime,
    })
    await act(async () => vi.advanceTimersByTime(1000))
    await waitFor(
      () =>
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'Comment updated',
          type: 'success',
        }),
      {advanceTimers: vi.advanceTimersByTime},
    )
  })

  it('displays an error if the update mutation failed', async () => {
    const errorMock = {
      request: {
        query: UPDATE_COMMENT_MUTATION,
        variables: {comment: 'not mocked!', id: '0'},
      },
      error: new Error('Update failed'),
    }
    const mocks = [...commentBankItemMocks(), errorMock]
    const {getByText, getByLabelText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    fireEvent.click(getByText('Edit comment: Comment item 0'))
    const input = getByLabelText('Edit comment')
    fireEvent.change(input, {target: {value: 'not mocked!'}})
    fireEvent.click(getByText('Save'))
    await act(async () => vi.advanceTimersByTime(1000))
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Error updating comment',
      type: 'error',
    })
  })
})
