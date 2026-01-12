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
import {commentBankItemMocks, searchMocks} from './mocks'
import LibraryManager from '../LibraryManager'
import fakeEnv from '@canvas/test-utils/fakeENV'

const flushAllTimersAndPromises = async () => {
  while (vi.getTimerCount() > 0) {
    await act(async () => {
      vi.runAllTimers()
    })
  }
}

vi.useFakeTimers()

describe('LibraryManager - search (part 2)', () => {
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
    fakeEnv.setup({comment_library_suggestions_enabled: true})
    setFocusToTextAreaMock = vi.fn()
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
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

  it('debounces the commentAreaText when displaying results', async () => {
    const mocks = [...commentBankItemMocks(), ...searchMocks()]
    const {getByText, queryByText} = render({
      props: defaultProps({commentAreaText: 'search'}),
      mocks,
    })

    // Advance by less than debounce delay (750ms) - should not show results yet
    await act(async () => vi.advanceTimersByTime(700))
    expect(queryByText('search result 0')).not.toBeInTheDocument()

    // Advance past debounce delay and wait for results to appear
    await act(async () => vi.advanceTimersByTime(100))
    await waitFor(() => expect(getByText('search result 0')).toBeInTheDocument())
  })

  it('doesnt rerender the suggestions after clicking on a suggested comment', async () => {
    const mocks = [
      ...commentBankItemMocks(),
      ...searchMocks({query: 'search'}),
      ...searchMocks({query: 'search results 0', first: 1}),
    ]
    const props = defaultProps({commentAreaText: 'search'})
    const {getByText, queryByText, rerender} = render({props, mocks})
    await act(async () => vi.advanceTimersByTime(1000))
    await waitFor(() => expect(getByText('search result 0')).toBeInTheDocument())
    fireEvent.click(getByText('search result 0'))
    await act(async () => vi.advanceTimersByTime(1000))

    render({
      props: defaultProps({commentAreaText: 'search result 0'}),
      mocks,
      func: rerender,
    })
    await act(async () => vi.advanceTimersByTime(1000))
    expect(queryByText('search result 0')).not.toBeInTheDocument()
  })
})
