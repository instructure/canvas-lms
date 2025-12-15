/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, cleanup} from '@testing-library/react'
import {DiscussionManagerUtilityContext, SearchContext} from '../../../utils/constants'
import {User} from '../../../../graphql/User'
import {responsiveQuerySizes} from '../../../utils'
import {useTranslationStore} from '../../../hooks/useTranslationStore'
import {ObserverContext} from '../../../utils/ObserverContext'

vi.mock('../../../utils')

vi.mock('../../../hooks/useTranslationStore')

const useTranslationStoreMock = useTranslationStore as unknown as any
const responsiveQuerySizesMock = responsiveQuerySizes as any

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
  responsiveQuerySizesMock.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const initalMockState = {
  activeLanguage: null,
  entries: {
    '1': {loading: false},
  },
  translateAll: false,
  addEntry: vi.fn(),
  removeEntry: vi.fn(),
  clearEntry: vi.fn(),
}

const defaultProviderProps = {
  translationLanguages: {
    current: [{id: 'en', name: 'English', translated_to_name: 'Translated to English'}],
  },
}

const setup = (props: any = {}, providerProps: any = {}) =>
  render(
    <ObserverContext.Provider
      value={{
        observerRef: {current: undefined},
        nodesRef: {current: new Map()},
        startObserving: () => {},
        stopObserving: () => {},
      }}
    >
      <DiscussionManagerUtilityContext.Provider
        value={{...defaultProviderProps, ...providerProps} as any}
      >
        <SearchContext.Provider value={{searchTerm: ''} as any}>
          <PostMessage
            discussionEntry={{id: '1'}}
            author={User.mock()}
            timingDisplay="Jan 1 2000"
            message="Posts are fun"
            title="Thoughts"
            {...props}
          />
        </SearchContext.Provider>
      </DiscussionManagerUtilityContext.Provider>
    </ObserverContext.Provider>,
  )

describe('PostMessage AI translation', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useTranslationStoreMock.mockImplementation((selector: any) => {
      return selector({...initalMockState})
    })
    ;(useTranslationStoreMock as any).getState = vi.fn(() => ({...initalMockState}))
  })

  it('should display loading spinner and text while translation is in progress', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: true,
          },
        },
      }
      return selector(state)
    })

    const {findByText, queryByTestId, queryByText} = setup()

    const spinner = await findByText('Translating')
    expect(spinner).toBeInTheDocument()
    const loadingText = await findByText('Translating Text')
    expect(loadingText).toBeInTheDocument()

    expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
    expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
    const translationSeparator = queryByText('Translated to English')
    expect(translationSeparator).not.toBeInTheDocument()
  })

  it('should display the translated message when translation is complete', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            translatedTitle: 'Translated title',
            translatedMessage: 'Translated message',
          },
        },
      }

      return selector(state)
    })

    const {findByTestId, findByText, queryByTestId} = setup()

    const translatedTitle = await findByTestId('post-title-translated')
    expect(translatedTitle).toHaveTextContent('Translated title')
    const translatedMessage = await findByTestId('post-message-translated')
    expect(translatedMessage).toHaveTextContent('Translated message')
    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()

    expect(queryByTestId('error_type_error')).not.toBeInTheDocument()
    expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
  })

  it('should display the translated title even if there is no message', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            translatedTitle: 'Translated message',
            translatedMessage: '',
          },
        },
      }

      return selector(state)
    })

    const {findByText, findByTestId, queryByTestId} = setup()

    const translatedTitle = await findByTestId('post-title-translated')
    expect(translatedTitle).toHaveTextContent('Translated message')
    expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()
  })

  it('should display the translated message even if there is no title', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            translatedTitle: '',
            translatedMessage: 'Translated message',
          },
        },
      }

      return selector(state)
    })

    const {findByText, findByTestId, queryByTestId} = setup()

    const translatedTitle = await findByTestId('post-message-translated')
    expect(translatedTitle).toHaveTextContent('Translated message')
    expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()
  })

  it('should display separator and error with error_type message if translation fails with generic error', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        activeLanguage: 'en',
        entries: {
          '1': {
            loading: false,
            language: 'en',
            error: {type: 'newError', message: 'There was an unexpected error during translation.'},
          },
        },
      }

      return selector(state)
    })

    const {findByText, findByTestId, queryByTestId} = setup()

    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()
    const errorMessage = await findByTestId('error_type_error')
    expect(errorMessage).toHaveTextContent('There was an unexpected error during translation.')
    expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
  })

  it('should display separator and error with error_type message if translation fails with specific error with error type', async () => {
    const message = 'very big error happened'

    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            error: {type: 'newError', message},
          },
        },
      }

      return selector(state)
    })

    const {findByText, findByTestId, queryByTestId} = setup()

    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()
    const errorMessage = await findByTestId('error_type_error')
    expect(errorMessage).toHaveTextContent(message)
    expect(queryByTestId('error_type_info')).not.toBeInTheDocument()
  })

  it('should display separator and error with info_type message if translation fails with specific error with info type', async () => {
    const message = 'little bit error happened'

    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            error: {type: 'info', message},
          },
        },
      }

      return selector(state)
    })

    const {findByText, findByTestId, queryByTestId} = setup()

    const translationSeparator = await findByText('Translated to English')
    expect(translationSeparator).toBeInTheDocument()
    const errorMessage = await findByTestId('error_type_info')
    expect(errorMessage).toHaveTextContent(message)
    expect(queryByTestId('error_type_error')).not.toBeInTheDocument()
  })

  it('should not display the translated message if error happens', async () => {
    useTranslationStoreMock.mockImplementation((selector: any) => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            error: {type: 'newError', message: 'There was an unexpected error during translation.'},
            translatedTitle: 'Translated title',
            translatedMessage: 'Translated message',
          },
        },
      }

      return selector(state)
    })

    const {queryByTestId} = setup()

    expect(queryByTestId('post-title-translated')).not.toBeInTheDocument()
    expect(queryByTestId('post-message-translated')).not.toBeInTheDocument()
  })

  describe('Translation Actions', () => {
    it('should display "Change translation language" and "Hide translation" links when translation is complete', async () => {
      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: false,
              language: 'en',
              translatedTitle: 'Translated title',
              translatedMessage: 'Translated message',
            },
          },
          removeEntry: vi.fn(),
          setModalOpen: vi.fn(),
        }

        return selector(state)
      })

      const {findByTestId} = setup()

      const changeLanguageLink = await findByTestId('change-language-link')
      expect(changeLanguageLink).toBeInTheDocument()
      expect(changeLanguageLink).toHaveTextContent('Change translation language')

      const hideTranslationLink = await findByTestId('hide-translation-link')
      expect(hideTranslationLink).toBeInTheDocument()
      expect(hideTranslationLink).toHaveTextContent('Hide translation')
    })

    it('should not display actions when there is no translation', async () => {
      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: false,
            },
          },
        }

        return selector(state)
      })

      const {queryByTestId} = setup()

      expect(queryByTestId('change-language-link')).not.toBeInTheDocument()
      expect(queryByTestId('hide-translation-link')).not.toBeInTheDocument()
    })

    it('should not display actions when translation is loading', async () => {
      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: true,
            },
          },
        }

        return selector(state)
      })

      const {queryByTestId} = setup()

      expect(queryByTestId('change-language-link')).not.toBeInTheDocument()
      expect(queryByTestId('hide-translation-link')).not.toBeInTheDocument()
    })

    it('should not display actions when there is an error', async () => {
      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: false,
              language: 'en',
              error: {type: 'newError', message: 'Error occurred'},
            },
          },
        }

        return selector(state)
      })

      const {queryByTestId} = setup()

      expect(queryByTestId('change-language-link')).not.toBeInTheDocument()
      expect(queryByTestId('hide-translation-link')).not.toBeInTheDocument()
    })

    it('should call setModalOpen when "Change translation language" is clicked', async () => {
      const setModalOpenMock = vi.fn()

      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: false,
              language: 'en',
              translatedTitle: 'Translated title',
              translatedMessage: 'Translated message',
            },
          },
          removeEntry: vi.fn(),
          setModalOpen: setModalOpenMock,
        }

        return selector(state)
      })

      const {findByTestId} = setup()

      const changeLanguageLink = await findByTestId('change-language-link')
      changeLanguageLink.click()

      expect(setModalOpenMock).toHaveBeenCalledWith('1', 'Posts are fun', undefined)
    })

    it('should call setModalOpen with originalTitle when id is "topic"', async () => {
      const setModalOpenMock = vi.fn()

      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            topic: {
              loading: false,
              language: 'en',
              translatedTitle: 'Translated title',
              translatedMessage: 'Translated message',
            },
          },
          removeEntry: vi.fn(),
          setModalOpen: setModalOpenMock,
        }

        return selector(state)
      })

      const {findByTestId} = setup({discussionEntry: undefined})

      const changeLanguageLink = await findByTestId('change-language-link')
      changeLanguageLink.click()

      expect(setModalOpenMock).toHaveBeenCalledWith('topic', 'Posts are fun', 'Thoughts')
    })

    it('should call clearEntry when "Hide translation" is clicked', async () => {
      const clearEntryMock = vi.fn()

      useTranslationStoreMock.mockImplementation((selector: any) => {
        const state = {
          ...initalMockState,
          entries: {
            '1': {
              loading: false,
              language: 'en',
              translatedTitle: 'Translated title',
              translatedMessage: 'Translated message',
            },
          },
          clearEntry: clearEntryMock,
          setModalOpen: vi.fn(),
        }

        return selector(state)
      })

      const {findByTestId} = setup()

      const hideTranslationLink = await findByTestId('hide-translation-link')
      hideTranslationLink.click()

      expect(clearEntryMock).toHaveBeenCalledWith('1')
    })

    it('should not display actions when translateAll is active', async () => {
      const state = {
        ...initalMockState,
        entries: {
          '1': {
            loading: false,
            language: 'en',
            translatedTitle: 'Translated title',
            translatedMessage: 'Translated message',
          },
        },
        translateAll: true,
        removeEntry: vi.fn(),
        setModalOpen: vi.fn(),
      }

      useTranslationStoreMock.mockImplementation((selector: any) => {
        return selector(state)
      })
      ;(useTranslationStoreMock as any).getState = vi.fn(() => state)

      const {queryByTestId} = setup(
        {},
        {
          enqueueTranslation: vi.fn(),
          entryTranslatingSet: new Set(),
        },
      )

      expect(queryByTestId('change-language-link')).not.toBeInTheDocument()
      expect(queryByTestId('hide-translation-link')).not.toBeInTheDocument()
    })
  })
})

describe('PostMessage intersection observer registration', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useTranslationStoreMock.mockImplementation((selector: any) => {
      return selector({...initalMockState})
    })
    ;(useTranslationStoreMock as any).getState = vi.fn(() => ({...initalMockState}))
  })

  it('should register the component with the observer during mount', () => {
    const observeMock = vi.fn()
    const unobserveMock = vi.fn()
    const observerMock = {
      observe: observeMock,
      unobserve: unobserveMock,
      disconnect: vi.fn(),
    }
    const nodesRefMock = {current: new Map()}

    render(
      <ObserverContext.Provider
        value={{
          observerRef: {current: observerMock as unknown as IntersectionObserver},
          nodesRef: nodesRefMock,
          startObserving: () => {},
          stopObserving: () => {},
        }}
      >
        <DiscussionManagerUtilityContext.Provider value={{...defaultProviderProps} as any}>
          <SearchContext.Provider value={{searchTerm: ''} as any}>
            <PostMessage
              discussionEntry={{id: '1'}}
              author={User.mock()}
              timingDisplay="Jan 1 2000"
              message="Posts are fun"
              title="Thoughts"
            />
          </SearchContext.Provider>
        </DiscussionManagerUtilityContext.Provider>
      </ObserverContext.Provider>,
    )

    expect(observeMock).toHaveBeenCalledTimes(1)
    expect(observeMock).toHaveBeenCalledWith(expect.any(Object))
    expect(nodesRefMock.current.has('1')).toBe(true)
  })

  it('should unobserve and remove from nodesRef on unmount', () => {
    const observeMock = vi.fn()
    const unobserveMock = vi.fn()
    const observerMock = {
      observe: observeMock,
      unobserve: unobserveMock,
      disconnect: vi.fn(),
    }
    const nodesRefMock = {current: new Map()}

    const {unmount} = render(
      <ObserverContext.Provider
        value={{
          observerRef: {current: observerMock as unknown as IntersectionObserver},
          nodesRef: nodesRefMock,
          startObserving: () => {},
          stopObserving: () => {},
        }}
      >
        <DiscussionManagerUtilityContext.Provider value={{...defaultProviderProps} as any}>
          <SearchContext.Provider value={{searchTerm: ''} as any}>
            <PostMessage
              discussionEntry={{id: '1'}}
              author={User.mock()}
              timingDisplay="Jan 1 2000"
              message="Posts are fun"
              title="Thoughts"
            />
          </SearchContext.Provider>
        </DiscussionManagerUtilityContext.Provider>
      </ObserverContext.Provider>,
    )

    expect(nodesRefMock.current.has('1')).toBe(true)

    unmount()

    expect(unobserveMock).toHaveBeenCalledTimes(1)
    expect(nodesRefMock.current.has('1')).toBe(false)
  })

  it('should not observe if observer is not available', () => {
    const nodesRefMock = {current: new Map()}

    render(
      <ObserverContext.Provider
        value={{
          observerRef: {current: undefined},
          nodesRef: nodesRefMock,
          startObserving: () => {},
          stopObserving: () => {},
        }}
      >
        <DiscussionManagerUtilityContext.Provider value={{...defaultProviderProps} as any}>
          <SearchContext.Provider value={{searchTerm: ''} as any}>
            <PostMessage
              discussionEntry={{id: '1'}}
              author={User.mock()}
              timingDisplay="Jan 1 2000"
              message="Posts are fun"
              title="Thoughts"
            />
          </SearchContext.Provider>
        </DiscussionManagerUtilityContext.Provider>
      </ObserverContext.Provider>,
    )

    expect(nodesRefMock.current.has('1')).toBe(true)
  })
})
