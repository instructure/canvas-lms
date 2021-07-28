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

import {render} from '@testing-library/react'
import React from 'react'
import {SearchSpan} from '../SearchSpan'

const setup = props => {
  return render(<SearchSpan searchTerm="" text="" {...props} />)
}

describe('SearchSpan', () => {
  it('should perform no highlights if no searchTerm is present', () => {
    const {queryAllByTestId} = setup()
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })

  it('should highlight search term if found in message', () => {
    const {queryAllByTestId} = setup({searchTerm: 'Posts', text: 'Posts'})
    expect(queryAllByTestId('highlighted-search-item').length).toBe(1)
  })

  it('should not create highlight spans if no term is found', () => {
    const {queryAllByTestId} = setup({searchTerm: 'Posts', text: 'A message'})
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })

  it('should highlight multiple terms in message', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'a longer message with multiple highlights here and here'
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
  })

  it('highlighting should be case-insensitive', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'here and HeRe'
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
  })

  it('should not highlight when in isolated view', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'here and HeRe',
      isIsolatedView: true
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })
})
