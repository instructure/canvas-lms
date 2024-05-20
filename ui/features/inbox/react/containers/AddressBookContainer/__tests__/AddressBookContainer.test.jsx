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
import {act, render, fireEvent, screen} from '@testing-library/react'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {AddressBookContainer} from '../AddressBookContainer'
import {handlers} from '../../../../graphql/mswHandlers'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

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
      current_user_id: 1,
    }
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AddressBookContainer open={true} {...props} />
      </ApolloProvider>
    )
  }

  describe('With Context Selection enabled', () => {
    const contextSelectionDefaultProps = {
      hasSelectAllFilterOption: true,
      includeCommonCourses: true,
    }

    describe('Rendering', () => {
      it('Does not show context select in initial menu', async () => {
        setup(contextSelectionDefaultProps)
        const items = await screen.findAllByTestId('address-book-item')
        expect(items.length).toBe(2)
        expect(screen.queryByText('Users')).toBeInTheDocument()
        expect(screen.queryByText('Courses')).toBeInTheDocument()
      })

      it('Does not show context select for initial "Courses" submenu', async () => {
        setup(contextSelectionDefaultProps)
        let items = await screen.findAllByTestId('address-book-item')
        fireEvent.mouseDown(items[0])

        items = await screen.findAllByTestId('address-book-item')
        expect(items.length).toBe(2)
        expect(screen.queryByText('Back')).toBeInTheDocument()
        expect(screen.queryByText('Testing 101')).toBeInTheDocument()
      })

      it('Does not show context select for initial users submenu', async () => {
        setup()
        let items = await screen.findAllByTestId('address-book-item')
        fireEvent.mouseDown(items[1])

        items = await screen.findAllByTestId('address-book-item')
        expect(items.length).toBe(4)
        expect(screen.queryByText('Back')).toBeInTheDocument()
        expect(screen.queryByText('Frederick Dukes')).toBeInTheDocument()
        expect(screen.queryByText('Trevor Fitzroy')).toBeInTheDocument()
        expect(screen.queryByText('Null Forge')).toBeInTheDocument()
      })

      it('Shows context select for course selection', async () => {
        setup(contextSelectionDefaultProps)
        let items = await screen.findAllByTestId('address-book-item')
        fireEvent.mouseDown(items[0])

        items = await screen.findAllByTestId('address-book-item')
        expect(items.length).toBe(2)
        expect(screen.queryByText('Back')).toBeInTheDocument()
        expect(screen.queryByText('Testing 101')).toBeInTheDocument()

        fireEvent.mouseDown(items[1])
        items = await screen.findAllByTestId('address-book-item')
        expect(items.length).toBe(3)
        expect(screen.queryByText('Back')).toBeInTheDocument()
        expect(screen.queryByText('All in Testing 101')).toBeInTheDocument()
        expect(screen.queryByText('People: 3')).toBeInTheDocument()
      })
    })
  })

  describe('Behaviors', () => {
    it('should render', () => {
      const {container} = setup()
      expect(container).toBeTruthy()
    })

    it('should filter menu by initial context', async () => {
      setup({
        activeCourseFilter: {contextID: 'course_123', contextName: 'course name'},
      })
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(1)
    })

    it('Should load the new courses and users submenu on initial load', async () => {
      setup()
      const items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)
      expect(screen.queryByText('Users')).toBeInTheDocument()
      expect(screen.queryByText('Courses')).toBeInTheDocument()
    })

    it('Should load data on initial request', async () => {
      setup()
      let items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)
      // open student sub-menu
      fireEvent.mouseDown(items[1])

      items = await screen.findAllByTestId('address-book-item')
      // Verify that all students and backbutton appear
      expect(items.length).toBe(4)
    })

    it('Should load new data when variables changes', async () => {
      setup()
      let items = await screen.findAllByTestId('address-book-item')
      fireEvent.mouseDown(items[1])
      items = await screen.findAllByTestId('address-book-item')
      // Expects there to be 3 users and 1 backbutton
      expect(items.length).toBe(4)
    })

    it('should filter menu when typing', async () => {
      jest.useFakeTimers()
      const {container} = setup()
      fireEvent.change(container.querySelector('input'), {target: {value: 'Fred'}})

      // for debouncing
      await act(async () => jest.advanceTimersByTime(1000))
      const items = await screen.findAllByTestId('address-book-item')
      // Expects The user Fred and a back button
      expect(items.length).toBe(2)
    })

    it('should return to last filter when backing out of search', async () => {
      jest.useFakeTimers()
      const {container} = setup()
      let items = await screen.findAllByTestId('address-book-item')
      // open users submenu
      fireEvent.mouseDown(items[1])

      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(4)
      fireEvent.change(container.querySelector('input'), {target: {value: 'Fred'}})

      // for debouncing
      await act(async () => jest.advanceTimersByTime(1000))
      items = await screen.findAllByTestId('address-book-item')
      // search results
      expect(items.length).toBe(2)
      fireEvent.mouseDown(items[0])

      await act(async () => jest.advanceTimersByTime(1000))
      items = await screen.findAllByTestId('address-book-item')
      // the student sub-menu
      expect(items.length).toBe(4)
    })

    it('Should clear text field when item is clicked', async () => {
      jest.useFakeTimers()
      const {container} = setup()
      let input = container.querySelector('input')
      fireEvent.change(input, {target: {value: 'Fred'}})
      expect(input.value).toBe('Fred')

      // for debouncing
      await act(async () => jest.advanceTimersByTime(1000))

      const items = await screen.findAllByTestId('address-book-item')
      // Expects Fred and a back button
      expect(items.length).toBe(2)

      fireEvent.mouseDown(items[0])
      input = container.querySelector('input')
      expect(input.value).toBe('')
    })

    it('should navigate through filters', async () => {
      setup()
      // Find initial courses and users sub-menu
      let items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)

      // Click courses submenu
      fireEvent.mouseDown(items[0])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)

      // Click back button which is always first position in submenu
      fireEvent.mouseDown(items[0])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)
    })

    it('Should be able to select only 1 tags when limit is 1', async () => {
      setup({limitTagCount: 1, open: true})
      // Find initial courses and users sub-menu
      let items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(2)

      // Click users submenu
      fireEvent.mouseDown(items[1])
      items = await screen.findAllByTestId('address-book-item')
      expect(items.length).toBe(4)

      // Click on 2 users to try to create 2 tags
      fireEvent.mouseDown(items[1])
      fireEvent.mouseDown(items[2])

      // Verify that only 1 tag was created
      const tags = await screen.findAllByTestId('address-book-tag')
      expect(tags.length).toBe(1)
    })
  })

  describe('Callbacks', () => {
    it('Should call onSelectedIdsChange when id changes', async () => {
      const onSelectedIdsChangeMock = jest.fn()
      setup({
        onSelectedIdsChange: onSelectedIdsChangeMock,
      })
      let items = await screen.findAllByTestId('address-book-item')
      fireEvent.mouseDown(items[1])

      items = await screen.findAllByTestId('address-book-item')
      fireEvent.mouseDown(items[1])

      expect(onSelectedIdsChangeMock.mock.calls.length).toBe(1)
      expect(onSelectedIdsChangeMock.mock.calls[0][0][0].name).toEqual('Frederick Dukes')
    })
  })
})
