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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import {handlers} from '../../../graphql/mswHandlers'
import MessageListActionContainer from '../MessageListActionContainer'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'

describe('MessageListActionContainer', () => {
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
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1
    }
  })

  const setup = overrideProps => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MessageListActionContainer {...overrideProps} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  describe('rendering', () => {
    it('should render', () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })

    it('should call onCourseFilterSelect when course selected', async () => {
      const mock = jest.fn()

      const component = setup({
        onCourseFilterSelect: mock
      })

      const courseDropdown = await component.findByTestId('course-select')
      fireEvent.click(courseDropdown)

      const option = await component.findByText('Fighting Magneto 101')
      fireEvent.click(option)

      expect(mock.mock.calls.length).toBe(1)
    })

    it('should callback to update mailbox when event fires', async () => {
      const mock = jest.fn()

      const component = setup({
        onSelectMailbox: mock
      })

      const mailboxDropdown = await component.findByLabelText('Mailbox Selection')
      fireEvent.click(mailboxDropdown)

      const option = await component.findByText('Sent')
      expect(option).toBeTruthy()
      fireEvent.click(option)

      expect(mock.mock.calls.length).toBe(1)
    })

    it('should call onSelectMailbox when mailbox changed', async () => {
      const mock = jest.fn()

      const component = setup({
        onSelectMailbox: mock
      })

      const mailboxDropdown = await component.findByLabelText('Mailbox Selection')
      fireEvent.click(mailboxDropdown)

      const option = await component.findByText('Sent')
      expect(option).toBeTruthy()
      fireEvent.click(option)

      expect(mock.mock.calls.length).toBe(1)
    })

    it('should load with selected mailbox set via props', async () => {
      const component = setup({
        activeMailbox: 'sent'
      })

      const mailboxDropdown = await component.findByDisplayValue('Sent')
      expect(mailboxDropdown).toBeTruthy()
    })
  })

  it('should have buttons disabled when their disabled states are true', async () => {
    const component = setup({
      deleteDisabled: true,
      archiveDisabled: true
    })

    const delBtn = await component.findByTestId('delete')
    const archBtn = await component.findByTestId('archive')
    expect(delBtn).toBeDisabled()
    expect(archBtn).toBeDisabled()
  })

  it('should have buttons enabled when their disabled states are false', async () => {
    const component = setup({
      deleteDisabled: false,
      archiveDisabled: false
    })

    const delBtn = await component.findByTestId('delete')
    const archBtn = await component.findByTestId('archive')
    expect(delBtn).not.toBeDisabled()
    expect(archBtn).not.toBeDisabled()
  })

  it('should have archive disabled when activeMailbox is sent', async () => {
    const component = setup({
      archiveDisabled: false,
      activeMailbox: 'sent'
    })

    const archBtn = await component.findByTestId('archive')
    expect(archBtn).toBeDisabled()
  })

  it('should show unarchive button when displayUnarchiveButton is true', async () => {
    const component = setup({
      archiveDisabled: false,
      displayUnarchiveButton: true
    })

    const unarchBtn = await component.findByTestId('unarchive')
    expect(unarchBtn).toBeTruthy()
  })

  it('should trigger confirm when unarchiving', async () => {
    window.confirm = jest.fn(() => true)
    const component = setup({
      archiveDisabled: false,
      displayUnarchiveButton: true,
      selectedConversations: [{test1: 'test1'}, {test2: 'test2'}]
    })

    const unarchBtn = await component.findByTestId('unarchive')
    fireEvent.click(unarchBtn)
    expect(window.confirm).toHaveBeenCalled()
  })

  it('should trigger confirm when deleting', async () => {
    window.confirm = jest.fn(() => true)
    const component = setup({
      deleteDisabled: false,
      selectedConversations: [{test1: 'test1'}, {test2: 'test2'}]
    })

    const deleteBtn = await component.findByTestId('delete')
    fireEvent.click(deleteBtn)
    expect(window.confirm).toHaveBeenCalled()
  })
})
