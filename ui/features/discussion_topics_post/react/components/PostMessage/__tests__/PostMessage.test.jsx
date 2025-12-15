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
import {render, screen, act, cleanup} from '@testing-library/react'
import {SearchContext} from '../../../utils/constants'
import {User} from '../../../../graphql/User'
import {responsiveQuerySizes} from '../../../utils'
import {ObserverContext} from '../../../utils/ObserverContext'

vi.mock('../../../utils')

const mediaQueryMock = {
  matches: true,
  media: '',
  onchange: null,
  addListener: vi.fn(),
  removeListener: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
  dispatchEvent: vi.fn(),
}

beforeAll(() => {
  window.matchMedia = vi.fn().mockImplementation(query => ({...mediaQueryMock, media: query}))
})

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = (props, {searchTerm = ''} = {}) => {
  return render(
    <ObserverContext.Provider
      value={{observerRef: {current: undefined}, nodesRef: {current: new Map()}}}
    >
      <SearchContext.Provider value={{searchTerm}}>
        <PostMessage
          author={User.mock()}
          timingDisplay="Jan 1 2000"
          message="Posts are fun"
          title="Thoughts"
          {...props}
        />
      </SearchContext.Provider>
    </ObserverContext.Provider>,
  )
}

describe('PostMessage', () => {
  it('displays the title', () => {
    const {getByText} = setup()
    expect(getByText('Thoughts')).toBeInTheDocument()
  })

  it('displays the title with screen reader text', () => {
    const {getByText} = setup()
    const screenReaderText = getByText('Discussion Topic: Thoughts')

    expect(screenReaderText).toBeInTheDocument()
    expect(screenReaderText.parentElement.parentElement.parentElement.tagName).toBe('SPAN')
  })

  it('displays the message', () => {
    const {getByText} = setup()
    expect(getByText('Posts are fun')).toBeInTheDocument()
  })

  it('displays the children', () => {
    const {getByText} = setup({
      children: <span>Smol children</span>,
    })
    expect(getByText('Smol children')).toBeInTheDocument()
  })

  describe('search highlighting', () => {
    it('should not highlight text if no search term is present', () => {
      const {queryAllByTestId} = setup()
      expect(queryAllByTestId('highlighted-search-item')).toHaveLength(0)
    })

    it('should highlight search terms in message', () => {
      const {queryAllByTestId} = setup({}, {searchTerm: 'Posts'})
      expect(queryAllByTestId('highlighted-search-item')).toHaveLength(1)
    })

    it('should highlight multiple terms in postmessage', () => {
      const {queryAllByTestId} = setup(
        {message: 'a longer message with multiple highlights here and here'},
        {searchTerm: 'here'},
      )
      expect(queryAllByTestId('highlighted-search-item')).toHaveLength(2)
    })

    it('highlighting should be case-insensitive', () => {
      const {queryAllByTestId} = setup(
        {message: 'a longer message with multiple highlights Here and here'},
        {searchTerm: 'here'},
      )
      expect(queryAllByTestId('highlighted-search-item')).toHaveLength(2)
    })

    it('updates the displayed message when the message prop changes', async () => {
      const {rerender} = setup({message: 'Initial message'})

      // Check initial render
      expect(screen.getByText('Initial message')).toBeInTheDocument()

      // Rerender with new props
      await act(async () => {
        rerender(
          <ObserverContext.Provider
            value={{observerRef: {current: undefined}, nodesRef: {current: new Map()}}}
          >
            <SearchContext.Provider value={{searchTerm: ''}}>
              <PostMessage
                author={User.mock()}
                timingDisplay="Jan 1 2000"
                message="Updated message"
                title="Thoughts"
              />
            </SearchContext.Provider>
          </ObserverContext.Provider>,
        )
      })

      // Check if the new message is displayed
      expect(screen.getByText('Updated message')).toBeInTheDocument()
      expect(screen.queryByText('Initial message')).not.toBeInTheDocument()
    })
  })
})
