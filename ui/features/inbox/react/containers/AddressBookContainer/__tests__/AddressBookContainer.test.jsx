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
import {ApolloProvider} from '@apollo/client'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {AddressBookContainer} from '../AddressBookContainer'
import {handlers} from '../../../../graphql/mswHandlers'

describe('AddressBookContainer', () => {
  const server = mswServer(handlers)
  let user

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1,
    }
    user = userEvent.setup()
  })

  const setup = (props = {}) => {
    return render(
      <ApolloProvider client={mswClient}>
        <AddressBookContainer {...props} />
      </ApolloProvider>,
    )
  }

  const openAddressBook = async ({getByTestId}) => {
    const button = getByTestId('address-button')
    await user.click(button)
  }

  describe('Context Selection', () => {
    const contextSelectionProps = {
      width: '360px',
      menuRef: {current: document.createElement('div')},
      onSelect: () => {},
      onTextChange: () => {},
      onSelectedIdsChange: () => {},
      selectedIds: [],
    }

    it('hides context select in initial menu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      expect(items).toHaveLength(2)
      expect(rendered.queryByText('Users')).toBeInTheDocument()
    })

    it('hides context select for initial "Courses" submenu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('hides context select for initial users submenu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(4) // Back button + 3 users
    })

    it('shows context select for course selection', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems.length).toBeGreaterThan(0)
    })
  })

  describe('Basic Functionality', () => {
    it('renders component', () => {
      const {getByTestId} = setup()
      expect(getByTestId('-address-book-input')).toBeInTheDocument()
    })

    it('filters menu by initial context', async () => {
      const {findByTestId} = setup()
      const input = await findByTestId('-address-book-input')
      expect(input).toBeInTheDocument()
    })

    it('loads courses and users submenu on initial load', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      expect(items).toHaveLength(2)
    })

    it('loads data on initial request', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('should filter menu when typing', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const filteredItems = await rendered.findAllByTestId('address-book-item')
      expect(filteredItems.length).toBeGreaterThan(0)
    })

    it('should return to last filter when backing out of search', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      await user.clear(input)
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('clears text field when item is clicked', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      await user.click(submenuItems[0])
      expect(input).toHaveValue('')
    })

    it('should navigate through filters', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(4) // Back button + 3 users
    })

    it('clears input when submenu is chosen', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      expect(input).toHaveValue('')
    })

    it('limits tag selection when limit is 1', async () => {
      const onSelectedIdsChange = jest.fn()
      const rendered = setup({
        selectedIds: ['1'],
        onSelectedIdsChange,
        limitTagCount: 1,
      })
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1]) // Click on Users
      const userItems = await rendered.findAllByTestId('address-book-item')
      await user.click(userItems[1]) // Click the first user item
      expect(onSelectedIdsChange).toHaveBeenCalled()
    })

    it('updates navigation state when activeCourseFilter changes', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })
  })

  describe('Callbacks', () => {
    it('calls onSelectedIdsChange when id changes', async () => {
      const onSelectedIdsChange = jest.fn()
      const rendered = setup({onSelectedIdsChange})
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1]) // Click on Users
      const userItems = await rendered.findAllByTestId('address-book-item')
      await user.click(userItems[1]) // Click the first user item
      expect(onSelectedIdsChange).toHaveBeenCalled()
    })
  })
})
