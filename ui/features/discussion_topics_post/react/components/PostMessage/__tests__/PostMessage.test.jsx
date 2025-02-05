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
import {render, screen, act, waitFor, cleanup} from '@testing-library/react'
import {DiscussionManagerUtilityContext, SearchContext} from '../../../utils/constants'
import {User} from '../../../../graphql/User'
import {getTranslation, responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

const mediaQueryMock = {
  matches: true,
  media: '',
  onchange: null,
  addListener: jest.fn(),
  removeListener: jest.fn(),
  addEventListener: jest.fn(),
  removeEventListener: jest.fn(),
  dispatchEvent: jest.fn(),
}

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(query => ({...mediaQueryMock, media: query}))
})

afterEach(() => {
  cleanup()
  jest.clearAllMocks()
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
    </SearchContext.Provider>,
  )
}

const setupWithTranslationLanguageSelected = (props, {searchTerm = ''} = {}) => {
  return render(
    <DiscussionManagerUtilityContext.Provider
      value={{
        translationLanguages: {
          current: [{id: 'en', name: 'English', translated_to_name: 'Translated to English'}],
        },
        translateTargetLanguage: 'en',
      }}
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
    </DiscussionManagerUtilityContext.Provider>,
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
          <SearchContext.Provider value={{searchTerm: ''}}>
            <PostMessage
              author={User.mock()}
              timingDisplay="Jan 1 2000"
              message="Updated message"
              title="Thoughts"
            />
          </SearchContext.Provider>,
        )
      })

      // Check if the new message is displayed
      expect(screen.getByText('Updated message')).toBeInTheDocument()
      expect(screen.queryByText('Initial message')).not.toBeInTheDocument()
    })
  })

  describe('AI translation', () => {
    it('should display the translated message when translation is complete', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {findByTestId, findByText} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      expect(getTranslation).toHaveBeenCalled()
      const translatedMessage = await findByTestId('post-message-translated')
      expect(translatedMessage.children[0]).toHaveTextContent('Translated message')
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
    })

    it('should not display the translated message if there is no translation', async () => {
      getTranslation.mockImplementation(() => Promise.resolve(''))

      const {queryByTestId, queryByText} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await queryByText('Translated to English')
      expect(translationSeparator).not.toBeInTheDocument()
    })

    it('should not display the translated message if the translation fails', async () => {
      getTranslation.mockImplementation(() => Promise.reject(new Error('Translation error')))

      const {queryByTestId, queryByText} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await queryByText('Translated to English')
      expect(translationSeparator).not.toBeInTheDocument()
    })
  })
})
