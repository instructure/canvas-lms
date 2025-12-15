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
import {act, fireEvent, render as rtlRender} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {commentBankItemMocks} from './mocks'
import LibraryManager from '../LibraryManager'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.useFakeTimers()

describe('LibraryManager - search (part 3)', () => {
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

  it('renders the suggestions as enabled if comment_library_suggestions_enabled is true', async () => {
    const {getByText, getByLabelText} = render({mocks: commentBankItemMocks()})
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    expect(getByLabelText('Show suggestions when typing')).toBeChecked()
  })

  it('renders the suggestions as disabled if comment_library_suggestions_enabled is false', async () => {
    fakeEnv.setup({comment_library_suggestions_enabled: false})
    const {getByText, getByLabelText} = render()
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    expect(getByLabelText('Show suggestions when typing')).not.toBeChecked()
  })
})
