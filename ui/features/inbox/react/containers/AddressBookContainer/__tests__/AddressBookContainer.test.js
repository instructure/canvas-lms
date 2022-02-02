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
import {ApolloProvider} from 'react-apollo'
import {render, fireEvent, screen} from '@testing-library/react'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {AddressBookContainer} from '../AddressBookContainer'
import {handlers} from '../../../../graphql/mswHandlers'

describe('Should load <AddressBookContainer> normally', () => {
  const server = mswServer(handlers)

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
    server.close()
  })

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1
    }
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AddressBookContainer open {...props} />
      </ApolloProvider>
    )
  }
  describe('Behaviors', () => {
    it('should render', () => {
      const {container} = setup()
      expect(container).toBeTruthy()
    })

    it('Should load data on initial request', async () => {
      setup()
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length > 0).toBe(true)
    })

    it('Should load new data when variables changes', async () => {
      setup()
      let items = await screen.findAllByTestId('address-book-item')
      fireEvent.mouseDown(items[0])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)
    })

    it('should filter menu when typing', async () => {
      const {container} = setup()
      fireEvent.change(container.querySelector('input'), {target: {value: 'Fred'}})
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(1)
    })

    it('should navigate through filters', async () => {
      setup()
      // Find all current items
      let items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(4)

      // Click item that is a sub menu
      fireEvent.mouseDown(items[0])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)

      // Click back button which is always first position in submenu
      fireEvent.mouseDown(items[0])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(4)
    })
  })

  describe('Callbacks', () => {
    it('Should call onSelectedIdsChange when id changes', async () => {
      const onSelectedIdsChangeMock = jest.fn()
      setup({
        onSelectedIdsChange: onSelectedIdsChangeMock
      })
      const items = await screen.findAllByTestId('address-book-item')
      fireEvent.click(items[3])
      expect(onSelectedIdsChangeMock.mock.calls.length).toBe(1)
    })
  })
})
