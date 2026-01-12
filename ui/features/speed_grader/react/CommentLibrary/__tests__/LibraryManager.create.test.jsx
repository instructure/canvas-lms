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
import {commentBankItemMocks, makeCreateMutationMock} from './mocks'
import LibraryManager from '../LibraryManager'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

describe('LibraryManager - create', () => {
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

  const variables = {comment: 'test comment', courseId: '1'}
  const overrides = {CommentBankItem: {comment: 'test comment'}}

  it('creates the comment and loads it when the "Add comment" button is clicked', async () => {
    const mutationMock = await makeCreateMutationMock({variables, overrides})
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText, getByLabelText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    const input = getByLabelText('Add comment to library')
    fireEvent.change(input, {target: {value: 'test comment'}})
    fireEvent.click(getByText('Add to Library'))
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    await waitFor(() => expect(getByText('test comment')).toBeInTheDocument(), {
      advanceTimers: vi.advanceTimersByTime,
    })
  })

  it('disables the "Add comment" button while a comment is being added to the library', async () => {
    const mutationMock = await makeCreateMutationMock({variables, overrides})
    const mocks = [...commentBankItemMocks(), ...mutationMock]
    const {getByText, getByLabelText} = render({mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    const input = getByLabelText('Add comment to library')
    fireEvent.change(input, {target: {value: 'test comment'}})
    fireEvent.click(getByText('Add to Library'))
    expect(getByText('Adding to Library').closest('button')).toBeDisabled()
  })

  it('displays an error if the create mutation failed', async () => {
    const {getByText, getByLabelText} = render()
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    const input = getByLabelText('Add comment to library')
    fireEvent.change(input, {target: {value: 'test comment'}})
    fireEvent.click(getByText('Add to Library'))
    await act(async () => vi.advanceTimersByTime(1000))
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Error creating comment',
      type: 'error',
    })
  })
})
