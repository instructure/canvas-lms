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
import {act, cleanup, fireEvent, render as rtlRender} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {commentBankItemMocks} from './mocks'
import LibraryManager from '../LibraryManager'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.useFakeTimers()

describe('LibraryManager - query', () => {
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

  it('renders a loading spinner while loading', () => {
    const {getByText} = render()
    expect(getByText('Loading comment library')).toBeInTheDocument()
  })

  it('displays an error if the comments couldnt be fetched', async () => {
    render({mocks: []})
    await act(async () => vi.advanceTimersByTime(1000))
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Error loading comment library',
      type: 'error',
    })
  })

  it('calls focus when a comment within the tray is clicked', async () => {
    const {getByText} = render()
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'), {detail: 1})
    fireEvent.click(getByText('Comment item 0'), {detail: 1})
    expect(setFocusToTextAreaMock).toHaveBeenCalled()
  })
})
