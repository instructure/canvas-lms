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

import {PostMessage} from '../PostMessage'
import React from 'react'
import {render} from '@testing-library/react'
import {SearchContext} from '../../../utils/constants'
import {User} from '../../../../graphql/User'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = (props, {searchTerm = ''} = {}) => {
  return render(
    <SearchContext.Provider value={{searchTerm}}>
      <PostMessage
        author={User.mock()}
        timingDisplay="Jan 1 2000"
        message="Posts are fun"
        title="Thoughts"
        {...props}
      />
    </SearchContext.Provider>
  )
}

describe('PostMessage', () => {
  it('displays the title', () => {
    const {queryByText} = setup()
    expect(queryByText('Thoughts')).toBeTruthy()
  })

  it('displays the title h2', () => {
    const {queryByText} = setup()
    const screenReaderText = queryByText('Discussion Topic: Thoughts')

    expect(screenReaderText).toBeTruthy()
    expect(screenReaderText.parentElement.parentElement.parentElement.tagName).toBe('H2')
  })

  it('displays the message', () => {
    const {queryByText} = setup()
    expect(queryByText('Posts are fun')).toBeTruthy()
  })

  it('displays the children', () => {
    const {queryByText} = setup({
      children: <span>Smol children</span>,
    })
    expect(queryByText('Smol children')).toBeTruthy()
  })

  describe('search highlighting', () => {
    it('should not highlight text if no search term is present', () => {
      const {queryAllByTestId} = setup()
      expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
    })

    it('should highlight search terms in message', () => {
      const {queryAllByTestId} = setup({}, {searchTerm: 'Posts'})
      expect(queryAllByTestId('highlighted-search-item').length).toBe(1)
    })

    it('should highlight multiple terms in postmessage', () => {
      const {queryAllByTestId} = setup(
        {message: 'a longer message with multiple highlights here and here'},
        {searchTerm: 'here'}
      )
      expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
    })

    it('highlighting should be case-insensitive', () => {
      const {queryAllByTestId} = setup(
        {message: 'a longer message with multiple highlights Here and here'},
        {searchTerm: 'here'}
      )
      expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
    })
  })
})
