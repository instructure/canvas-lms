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
import {AddressBook, COURSE_TYPE, BACK_BUTTON_TYPE} from '../AddressBook'

const demoData = {
  contextData: [
    {id: 'course_11', name: 'Test 101'},
    {id: 'course_12', name: 'History 101'},
    {id: 'course_13', name: 'English 101'}
  ],
  userData: [
    {id: '1', name: 'Rob Orton', full_name: 'Rob Orton', pronouns: null},
    {id: '2', name: 'Matthew Lemon', full_name: 'Matthew Lemon', pronouns: null},
    {id: '3', name: 'Drake Harper', full_name: 'Drake Harpert', pronouns: null},
    {id: '4', name: 'Davis Hyer', full_name: 'Davis Hyer', pronouns: null, isLast: true}
  ]
}

const defaultProps = {
  menuData: demoData,
  onUserFilterSelect: jest.fn()
}

const setup = props => {
  return render(<AddressBook {...props} />)
}

describe('Address Book Component', () => {
  describe('Rendering', () => {
    it('Should render', () => {
      const component = setup(defaultProps)
      expect(component).toBeTruthy()
    })

    it('Should render popup menu when prop is true', async () => {
      setup({...defaultProps, open: true})
      const popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
    })

    it('Should render a text input', async () => {
      const {findByTestId} = setup(defaultProps)
      const input = await findByTestId('address-book-input')
      expect(input).toBeTruthy()
    })

    it('Should render back button when isSubMenu is present', async () => {
      setup({...defaultProps, isSubMenu: true, open: true})
      const backItem = await screen.findByText('Back')
      expect(backItem).toBeTruthy()
    })

    it('Should render header text when HeaderText is present', async () => {
      const headerText = 'Test Header Text'
      setup({...defaultProps, open: true, isSubMenu: true, headerText})
      const headerItem = await screen.findByText(headerText)
      expect(headerItem).toBeTruthy()
    })
  })

  describe('Behaviors', () => {
    it('Should render popup menu when button is clicked', async () => {
      const {container} = setup({...defaultProps})
      const button = container.querySelector('button')
      fireEvent.click(button)
      const popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
    })

    it('Should close popup menu when address button is pressed and popup is open', async () => {
      const {container} = setup({...defaultProps, open: true})
      const button = container.querySelector('button')
      fireEvent.click(button)
      const popover = screen.queryByTestId('address-book-popover')
      expect(popover).toBeFalsy()
    })

    it('Should close popup menu when focus is changed', async () => {
      const {container} = setup({...defaultProps})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      let popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
      fireEvent.blur(input)
      popover = screen.queryByTestId('address-book-popover')
      expect(popover).toBeFalsy()
    })

    it('Should render popup menu when textInput is focused', async () => {
      const {container} = setup({...defaultProps})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      const popover = await screen.findByTestId('address-book-popover')
      expect(popover).toBeTruthy()
    })

    it('Should pass back ID of item when selected', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, open: true, onSelect: onSelectSpy})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[0])
      expect(onSelectSpy.mock.calls[0][0]).toBe('subMenuCourse')
    })

    it('Should select item when navigating down and enter key is pressed', async () => {
      const onSelectSpy = jest.fn()
      const {container} = setup({...defaultProps, open: true, onSelect: onSelectSpy})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      fireEvent.keyDown(input, {key: 'ArrowDown', keyCode: 40})
      fireEvent.keyDown(input, {key: 'Enter', keyCode: 13})
      expect(onSelectSpy.mock.calls.length).toBe(1)
      expect(onSelectSpy.mock.calls[0][0]).toBe('subMenuStudents')
    })

    it('Should select item when navigating up and enter key is pressed', () => {
      const onSelectSpy = jest.fn()
      const {container} = setup({...defaultProps, open: true, onSelect: onSelectSpy})
      const input = container.querySelector('input')
      fireEvent.focus(input)
      fireEvent.keyDown(input, {key: 'ArrowUp', keyCode: 38})
      fireEvent.keyDown(input, {key: 'ArrowUp', keyCode: 38})
      fireEvent.keyDown(input, {key: 'Enter', keyCode: 13})
      expect(onSelectSpy.mock.calls.length).toBe(1)
      expect(onSelectSpy.mock.calls[0][0]).toBe('subMenuCourse')
    })

    it('Should render loading bar below rendered menu items when loading more menu data', async () => {
      const {queryByTestId} = setup({
        ...defaultProps,
        open: true,
        isLoading: true,
        isLoadingMoreMenuData: true
      })
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length > 0).toBe(true)
      expect(queryByTestId('menu-loading-spinner')).toBeInTheDocument()
    })

    it('Should not render old data when clicking into a new sub-menu', () => {
      const {queryByTestId, queryAllByTestId} = setup({
        ...defaultProps,
        open: true,
        isLoading: true,
        isLoadingMoreMenuData: false
      })

      expect(queryAllByTestId('address-book-item').length).toBe(0)
      expect(queryByTestId('address-book-popover')).not.toBeInTheDocument()
      expect(queryByTestId('menu-loading-spinner')).toBeInTheDocument()
    })
  })

  describe('Tags', () => {
    it('Should render tag when item is selected', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, open: true, isSubMenu: true, onSelect: onSelectSpy})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      const tag = await screen.findByTestId('address-book-tag')
      expect(tag).toBeTruthy()
    })

    it('Should be able to select 2 tags when no limit is set', async () => {
      setup({...defaultProps, open: true, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      fireEvent.mouseDown(items[5])
      const tags = await screen.findAllByTestId('address-book-tag')
      expect(tags.length).toBe(2)
    })

    it('Should be able to select only 1 tags when limit is 1', async () => {
      setup({...defaultProps, open: true, limitTagCount: 1, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      fireEvent.mouseDown(items[5])
      const tags = await screen.findAllByTestId('address-book-tag')
      expect(tags.length).toBe(1)
    })

    it('Should pass back selected IDs as an array', async () => {
      const onSelectedIdsChangeMock = jest.fn()
      setup({
        ...defaultProps,
        open: true,
        limitTagCount: 1,
        onSelectedIdsChange: onSelectedIdsChangeMock,
        isSubMenu: true
      })
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      await screen.findByTestId('address-book-tag')
      expect(onSelectedIdsChangeMock.mock.calls[0][0]).toStrictEqual([demoData.userData[0]])
    })

    it('Should be able to remove a tag', async () => {
      setup({...defaultProps, open: true, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      const tag = await screen.findByTestId('address-book-tag')
      expect(tag).toBeInTheDocument()
      fireEvent.click(tag.querySelector('span'))
      expect(screen.queryByTestId('address-book-tag')).not.toBeInTheDocument()
    })
  })

  describe('Callbacks', () => {
    it('Should send search input through onTextChange callback', async () => {
      const onChangeSpy = jest.fn()
      const {findByTestId} = setup({...defaultProps, onTextChange: onChangeSpy})
      const input = await findByTestId('address-book-input')
      fireEvent.change(input, {target: {value: 'Test'}})
      expect(onChangeSpy.mock.calls.length).toBe(1)
    })

    it('Should select item when clicked', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, open: true, onSelect: onSelectSpy, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      expect(onSelectSpy.mock.calls.length).toBe(1)
    })

    it('Should call onUserFilterSelect when item is selected', async () => {
      const onSelectSpy = jest.fn()
      const onUserFilterSelectSpy = jest.fn()
      setup({
        ...defaultProps,
        open: true,
        onSelect: onSelectSpy,
        onUserFilterSelect: onUserFilterSelectSpy,
        isSubMenu: true
      })
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[4])
      expect(onUserFilterSelectSpy.mock.calls.length).toBe(1)
    })

    it('Should call back for group clicks', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, open: true, onSelect: onSelectSpy, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[1])
      expect(onSelectSpy.mock.calls.length).toBe(1)
      expect(onSelectSpy.mock.calls[0][0].includes(COURSE_TYPE)).toBe(true)
    })

    it('Should call back for back click', async () => {
      const onSelectSpy = jest.fn()
      setup({...defaultProps, open: true, onSelect: onSelectSpy, isSubMenu: true})
      const popover = await screen.findByTestId('address-book-popover')
      const items = popover.querySelectorAll('li')
      fireEvent.mouseDown(items[0])
      expect(onSelectSpy.mock.calls.length).toBe(1)
      expect(onSelectSpy.mock.calls[0][0].includes(BACK_BUTTON_TYPE)).toBe(true)
    })
  })
  describe('Intersection Observer', () => {
    const intersectionObserverMock = () => ({
      observe: () => null,
      unobserve: () => null
    })
    beforeEach(() => {
      window.IntersectionObserver = jest.fn().mockImplementation(intersectionObserverMock)
    })
    it('Should create an observer when more data is available', async () => {
      const component = setup({
        ...defaultProps,
        open: true,
        hasMoreMenuData: true
      })
      expect(component).toBeTruthy()
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length > 0).toBe(true)

      expect(window.IntersectionObserver).toHaveBeenCalledTimes(1)
    })

    it('Should not create an observer when no more data is available', async () => {
      const component = setup({
        ...defaultProps,
        open: true,
        hasMoreMenuData: false
      })
      expect(component).toBeTruthy()
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length > 0).toBe(true)

      expect(window.IntersectionObserver).toHaveBeenCalledTimes(0)
    })
  })
})
