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
import {render, screen} from '@testing-library/react'
import {AddressBook, USER_TYPE, CONTEXT_TYPE} from '../AddressBook'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock jQuery to prevent flashError errors from unrelated components
jest.mock('jquery', () => {
  const jQueryMock = {
    flashError: jest.fn(),
    Deferred: jest.fn(() => ({
      resolve: jest.fn(),
      reject: jest.fn(),
      promise: jest.fn(),
    })),
  }
  return jest.fn(() => jQueryMock)
})

const server = mswServer(handlers)
beforeAll(() => {
  // Start the server with more specific options
  server.listen({
    onUnhandledRequest: 'bypass', // Don't throw on unhandled requests
  })
})

beforeEach(() => {
  // Set up default ENV values for all tests
  fakeENV.setup({
    current_user_id: 1,
    SETTINGS: {
      can_add_pronouns: false,
    },
  })
})

afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
  jest.clearAllMocks()
})

afterAll(() => {
  server.close()
})

const demoData = {
  contextData: [
    {id: 'course_11', name: 'Test 101', itemType: CONTEXT_TYPE},
    {id: 'course_12', name: 'History 101', itemType: CONTEXT_TYPE},
    {id: 'course_13', name: 'English 101', itemType: CONTEXT_TYPE, isLast: true},
  ],
  userData: [
    {id: '1', name: 'Rob Orton', full_name: 'Rob Orton', pronouns: 'he/him', itemType: USER_TYPE},
    {
      id: '2',
      name: 'Matthew Lemon',
      full_name: 'Matthew Lemon',
      pronouns: null,
      itemType: USER_TYPE,
    },
    {
      id: '3',
      name: 'Drake Harper',
      full_name: 'Drake Harpert',
      pronouns: null,
      itemType: USER_TYPE,
    },
    {
      id: '4',
      name: 'Davis Hyer',
      full_name: 'Davis Hyer',
      pronouns: null,
      isLast: true,
      itemType: USER_TYPE,
    },
  ],
}

const defaultProps = {
  menuData: demoData,
  onUserFilterSelect: jest.fn(),
  setIsMenuOpen: jest.fn(),
}

const setup = props => {
  return render(
    <ApolloProvider client={mswClient}>
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <AddressBook {...props} />
      </AlertManagerContext.Provider>
    </ApolloProvider>,
  )
}

describe('Address Book Component', () => {
  describe('Rendering', () => {
    it('Should render', () => {
      const component = setup(defaultProps)
      expect(component).toBeTruthy()
    })

    it('Should render popup menu when prop is true', async () => {
      setup({...defaultProps, isMenuOpen: true})
      const popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
    })

    it('Should render a text input', async () => {
      const {findByTestId} = setup(defaultProps)
      const input = await findByTestId('-address-book-input')
      expect(input).toBeTruthy()
    })

    it('Should render back button when isSubMenu is present', async () => {
      setup({...defaultProps, isSubMenu: true, isMenuOpen: true})
      const backItem = await screen.findByText('Back')
      expect(backItem).toBeTruthy()
    })

    it('Should render header text when HeaderText is present', async () => {
      const headerText = 'Test Header Text'
      setup({...defaultProps, isMenuOpen: true, isSubMenu: true, headerText})
      const headerItem = await screen.findByText(headerText)
      expect(headerItem).toBeTruthy()
    })

    describe('Pronouns', () => {
      describe('can_add_pronouns disabled', () => {
        beforeEach(() => {
          fakeENV.setup({
            current_user_id: 1,
            SETTINGS: {
              can_add_pronouns: false,
            },
          })
        })

        it('do not show up pronouns', async () => {
          // Create test data with a user that has pronouns but they should not be shown
          const testUserWithPronouns = {
            id: '1',
            name: 'Test User',
            full_name: 'Test User',
            pronouns: 'he/him',
            itemType: USER_TYPE,
          }

          const testData = {
            contextData: [],
            userData: [testUserWithPronouns],
          }

          const mockSetIsMenuOpen = jest.fn()
          const {queryByText} = setup({
            menuData: testData,
            isMenuOpen: true,
            isSubMenu: true,
            setIsMenuOpen: mockSetIsMenuOpen,
            onUserFilterSelect: jest.fn(),
          })

          // Wait for the user's name to appear
          const userText = await screen.findByText('Test User')
          expect(userText).toBeInTheDocument()

          // Verify ENV settings
          expect(ENV.SETTINGS.can_add_pronouns).toBe(false)

          // Verify pronouns are not shown
          expect(queryByText('he/him')).not.toBeInTheDocument()
        })
      })
      describe('can_add_pronouns enabled', () => {
        beforeEach(() => {
          fakeENV.setup({
            current_user_id: 1,
            SETTINGS: {
              can_add_pronouns: true,
            },
          })
        })

        it('Show up pronouns if pronouns is not null', async () => {
          // Create test data with a user that has pronouns
          const testUserWithPronouns = {
            id: '1',
            name: 'Test User',
            full_name: 'Test User',
            pronouns: 'they/them',
            itemType: USER_TYPE,
          }

          const testData = {
            contextData: [],
            userData: [testUserWithPronouns],
          }

          const mockSetIsMenuOpen = jest.fn()
          setup({
            menuData: testData,
            isMenuOpen: true,
            isSubMenu: true,
            setIsMenuOpen: mockSetIsMenuOpen,
            onUserFilterSelect: jest.fn(),
          })

          // Wait for the user's name to appear
          const userText = await screen.findByText('Test User')
          expect(userText).toBeInTheDocument()

          // Verify ENV settings
          expect(ENV.SETTINGS.can_add_pronouns).toBe(true)
        })

        it('Do not show up pronouns if pronouns is null', async () => {
          const mockSetIsMenuOpen = jest.fn()
          const props = {...defaultProps}
          props.menuData.userData[0].pronouns = null
          const {queryByText} = setup({
            ...props,
            isMenuOpen: true,
            isSubMenu: true,
            setIsMenuOpen: mockSetIsMenuOpen,
          })
          await screen.findByTestId('address-book-popover')
          expect(queryByText('he/him')).not.toBeInTheDocument()
        })
      })
    })
  })
})
