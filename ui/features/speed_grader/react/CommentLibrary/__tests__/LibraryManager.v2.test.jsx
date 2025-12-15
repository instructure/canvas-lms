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
import {MockedProvider} from '@apollo/client/testing'
import {act, render as rtlRender, waitFor} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {commentBankItemMocksV2} from './mocks'
import LibraryManager from '../LibraryManager'

vi.useFakeTimers()

describe('LibraryManager - query with v2 mocks', () => {
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
    setFocusToTextAreaMock = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
    window.ENV = {}
  })

  const render = ({
    props = defaultProps(),
    mocks = commentBankItemMocksV2(),
    func = rtlRender,
  } = {}) =>
    func(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <LibraryManager {...props} />
      </MockedProvider>,
    )

  it('fetches all pages', async () => {
    const mocks = commentBankItemMocksV2()
    const {getByText, rerender} = render({
      mocks,
    })
    await act(async () => vi.advanceTimersByTime(1000))
    await waitFor(() => expect(getByText('15')).toBeInTheDocument())

    // Simulate typing "search" in the comment area
    render({
      props: defaultProps({commentAreaText: 'search'}),
      mocks,
      func: rerender,
    })

    await act(async () => vi.advanceTimersByTime(1000))
    await waitFor(() => expect(getByText('Comment item 2')).toBeInTheDocument())

    expect(getByText('15')).toBeInTheDocument()
  })
})
