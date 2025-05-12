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
import {fireEvent, render, screen} from '@testing-library/react'
import {AddressBook, USER_TYPE, CONTEXT_TYPE} from '../AddressBook'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = mswServer(handlers)
beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
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
  describe('Behaviors', () => {
    it('Should set popup menu to open when button is pressed', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({...defaultProps, setIsMenuOpen: mockSetIsMenuOpen})
      const button = container.querySelector('button')
      fireEvent.click(button)
      expect(mockSetIsMenuOpen).toHaveBeenCalled()
    })

    it('Should set popup menu to false when address button is pressed and popup is open', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({
        ...defaultProps,
        isMenuOpen: true,
        setIsMenuOpen: mockSetIsMenuOpen,
      })
      const button = container.querySelector('button')
      fireEvent.click(button)
      expect(mockSetIsMenuOpen).toHaveBeenCalledWith(false)
    })

    it('Should set popup menu to true when down arrow is pressed', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({
        ...defaultProps,
        isMenuOpen: true,
        setIsMenuOpen: mockSetIsMenuOpen,
      })
      const button = container.querySelector('button')
      fireEvent.click(button)
      const input = container.querySelector('input')
      fireEvent.keyDown(input, {key: 'ArrowDown', code: 'ArrowDown'})
      expect(mockSetIsMenuOpen).toHaveBeenCalledWith(false)
    })

    it('Should set popup menu to false when focus is changed', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({
        ...defaultProps,
        setIsMenuOpen: mockSetIsMenuOpen,
        isMenuOpen: true,
      })
      const input = container.querySelector('input')
      fireEvent.focus(input)
      const popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
      fireEvent.blur(input)
      expect(mockSetIsMenuOpen).toHaveBeenCalledWith(false)
    })

    it('Should not set popup menu to true when textInput is focused', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({...defaultProps, setIsMenuOpen: mockSetIsMenuOpen})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      expect(mockSetIsMenuOpen).not.toHaveBeenCalled()
    })

    it('Should set popup menu to true when textInput is clicked', async () => {
      const mockSetIsMenuOpen = jest.fn()
      const {container} = setup({...defaultProps, setIsMenuOpen: mockSetIsMenuOpen})
      const input = container.querySelector('input')
      fireEvent.click(input)
      expect(mockSetIsMenuOpen).toHaveBeenCalledWith(true)
    })

    it('Should pass back ID of item when selected', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, isMenuOpen: true, onSelect: onSelectSpy})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[0])
      expect(onSelectSpy.mock.calls[0][0].id).toBe('subMenuCourse')
    })

    it('Should select item when navigating down and enter key is pressed', async () => {
      const onSelectSpy = jest.fn()
      const {container} = setup({...defaultProps, isMenuOpen: true, onSelect: onSelectSpy})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      fireEvent.keyDown(input, {key: 'ArrowDown', keyCode: 40})
      fireEvent.keyDown(input, {key: 'Enter', keyCode: 13})
      expect(onSelectSpy.mock.calls).toHaveLength(1)
      expect(onSelectSpy.mock.calls[0][0].id).toBe('subMenuUsers')
    })

    it('Should select item when navigating up and enter key is pressed', () => {
      const onSelectSpy = jest.fn()
      const {container} = setup({...defaultProps, isMenuOpen: true, onSelect: onSelectSpy})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      fireEvent.keyDown(input, {key: 'ArrowUp', keyCode: 38})
      fireEvent.keyDown(input, {key: 'ArrowUp', keyCode: 38})
      fireEvent.keyDown(input, {key: 'Enter', keyCode: 13})
      expect(onSelectSpy.mock.calls).toHaveLength(1)
      expect(onSelectSpy.mock.calls[0][0].id).toBe('subMenuCourse')
    })

    it('Should render loading bar below rendered menu items when loading more menu data', async () => {
      const {queryByTestId} = setup({
        ...defaultProps,
        isMenuOpen: true,
        isLoading: true,
        isLoadingMoreMenuData: true,
      })
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length > 0).toBe(true)
      expect(queryByTestId('menu-loading-spinner')).toBeInTheDocument()
    })

    it('Should not render old data when clicking into a new sub-menu', () => {
      const {queryByTestId, queryAllByTestId} = setup({
        ...defaultProps,
        isMenuOpen: true,
        isLoading: true,
        isLoadingMoreMenuData: false,
      })

      expect(queryAllByTestId('address-book-item')).toHaveLength(0)
      expect(queryByTestId('address-book-popover')).not.toBeInTheDocument()
      expect(queryByTestId('menu-loading-spinner')).toBeInTheDocument()
    })
  })
})
