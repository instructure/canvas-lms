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
import React, {useState} from 'react'
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

const setupWithTranslationLanguageSelected = (
  props,
  {searchTerm = '', loading = false, translateTargetLanguage = 'en'} = {},
) => {
  const entryId = 'asdasd'
  const Wrapper = ({children}) => {
    const initSet = new Set()
    initSet.add(entryId)
    const [entryTranslatingSet, setEntryTranslatingSet] = useState(initSet)

    return (
      <DiscussionManagerUtilityContext.Provider
        value={{
          translationLanguages: {
            current: [{id: 'en', name: 'English', translated_to_name: 'Translated to English'}],
          },
          translateTargetLanguage,
          entryTranslatingSet,
          setEntryTranslating: () => {
            const newSet = new Set(entryTranslatingSet)
            if (loading) {
              newSet.add(entryId)
            } else {
              newSet.delete(entryId)
            }

            setEntryTranslatingSet(newSet)
          },
        }}
      >
        <SearchContext.Provider value={{searchTerm}}>{children}</SearchContext.Provider>
      </DiscussionManagerUtilityContext.Provider>
    )
  }

  return render(
    <Wrapper>
      <PostMessage
        discussionEntry={{id: entryId}}
        author={User.mock()}
        timingDisplay="Jan 1 2000"
        message="Posts are fun"
        title="Thoughts"
        {...props}
      />
    </Wrapper>,
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
    it('should display loading spinner and text while translation is in progress', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {findByText} = setupWithTranslationLanguageSelected(
        {
          message: '<p>Leforditando uzenet<p/>',
          title: 'Gondolatok',
        },
        {loading: true},
      )

      expect(getTranslation).toHaveBeenCalled()
      const spinner = await findByText('Translating')
      expect(spinner).toBeInTheDocument()
      const loadingText = await findByText('Translating Text')
      expect(loadingText).toBeInTheDocument()
    })

    it('should not display separator and translated message while translation is in progress', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {queryByText, queryByTestId} = setupWithTranslationLanguageSelected(
        {
          message: '<p>Leforditando uzenet<p/>',
          title: 'Gondolatok',
        },
        {loading: true},
      )

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await queryByText('Translated to English')
      expect(translationSeparator).not.toBeInTheDocument()
    })

    it('should display the translated message when translation is complete', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {findByTestId, findByText} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      expect(getTranslation).toHaveBeenCalled()
      const translatedTitle = await findByTestId('post-title-translated')
      expect(translatedTitle.children[0]).toHaveTextContent('Translated message')
      const translatedMessage = await findByTestId('post-message-translated')
      expect(translatedMessage.children[0]).toHaveTextContent('Translated message')
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
    })

    it('should not display error when translation is complete', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      expect(getTranslation).toHaveBeenCalled()
      expect(queryByTestId('error_type_error')).not.toBeInTheDocument()
      expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
    })

    it('should display the translated title even if there is no message', async () => {
      getTranslation
        .mockImplementationOnce(() => Promise.resolve('<p>Translated message</p>'))
        .mockImplementationOnce(() => Promise.resolve(''))

      const {findByTestId, findByText, queryByTestId} = setupWithTranslationLanguageSelected({
        message: '',
        title: 'Gondolatok',
      })

      expect(getTranslation).toHaveBeenCalled()
      const translatedTitle = await findByTestId('post-title-translated')
      expect(translatedTitle.children[0]).toHaveTextContent('Translated message')
      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
    })

    it('should display the translated message even if there is no title', async () => {
      getTranslation
        .mockImplementationOnce(() => Promise.resolve(''))
        .mockImplementationOnce(() => Promise.resolve('<p>Translated message</p>'))

      const {findByTestId, findByText, queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: '',
      })

      expect(getTranslation).toHaveBeenCalled()
      const translatedTitle = await findByTestId('post-message-translated')
      expect(translatedTitle.children[0]).toHaveTextContent('Translated message')
      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
    })

    it('should not display separator and translated message if there is no translation', async () => {
      getTranslation.mockImplementation(() => Promise.resolve(''))

      const {queryByTestId, queryByText} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await queryByText('Translated to English')
      expect(translationSeparator).not.toBeInTheDocument()
    })

    it('should not display separator and translated message if language is not set or reset', async () => {
      getTranslation.mockImplementation(() => Promise.resolve('<p>Translated message</p>'))

      const {queryByTestId, queryByText} = setupWithTranslationLanguageSelected(
        {
          message: '<p>Leforditando uzenet<p/>',
          title: 'Gondolatok',
        },
        {translateTargetLanguage: null},
      )

      expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
      const translationSeparator = await queryByText('Translated to English')
      expect(translationSeparator).not.toBeInTheDocument()
    })

    it('should display separator and error with error_type message if translation fails with generic error', async () => {
      getTranslation.mockImplementation(() => Promise.reject(new Error('Translation error')))

      const {findByText, findByTestId, queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
      const errorMessage = await findByTestId('error_type_error')
      expect(errorMessage).toHaveTextContent('There was an unexpected error during translation.')
      expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
    })

    it('should display separator and error with error_type message if translation fails with specific error with error type', async () => {
      const message = 'very big error happened'
      const error = new Error()
      Object.assign(error, {translationError: {type: 'newError', message}})
      getTranslation.mockImplementation(() => Promise.reject(error))

      const {findByText, findByTestId, queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
      const errorMessage = await findByTestId('error_type_error')
      expect(errorMessage).toHaveTextContent(message)
      expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
    })

    it('should display separator and error with info_type message if translation fails with specific error with info type', async () => {
      const message = 'little bit error happened'
      const error = new Error()
      Object.assign(error, {translationError: {type: 'info', message}})
      getTranslation.mockImplementation(() => Promise.reject(error))

      const {findByText, findByTestId, queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      const translationSeparator = await findByText('Translated to English')
      expect(translationSeparator).toBeInTheDocument()
      const errorMessage = await findByTestId('error_type_info')
      expect(errorMessage).toHaveTextContent(message)
      expect(queryByTestId('error_type_error')).not.toBeInTheDocument()
    })

    it('should not display the translated message if error happens', async () => {
      getTranslation.mockImplementation(() => Promise.reject(new Error('Translation error')))

      const {queryByTestId} = setupWithTranslationLanguageSelected({
        message: '<p>Leforditando uzenet<p/>',
        title: 'Gondolatok',
      })

      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
      await waitFor(() => expect(getTranslation).toHaveBeenCalled())
      expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
    })
  })
})
