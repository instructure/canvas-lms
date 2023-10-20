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

// until InstUI supports break points with multiple queries
describe.skip('MessageListActionContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })
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
      current_user_id: 1,
    }
  })

  const setup = overrideProps => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MessageListActionContainer
            activeMailbox="inbox"
            onCompose={jest.fn()}
            onReply={jest.fn()}
            onReplyAll={jest.fn()}
            onForward={jest.fn()}
            onSelectMailbox={jest.fn()}
            {...overrideProps}
          />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  describe('rendering', () => {
    it('should render', () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })

    it('should render without waiting for queries to finish', () => {
      const component = setup()
      expect(component.queryByTestId('tool-bar')).toBeTruthy()
    })

    it('should render All Courses option', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select')
      fireEvent.click(courseDropdown)
      expect(await queryByText('All Courses')).toBeInTheDocument()
    })

    it('should render concluded courses option', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select')
      fireEvent.click(courseDropdown)
      expect(await queryByText('Concluded Courses')).toBeInTheDocument()
    })

    it('should render concluded courses', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select')
      fireEvent.click(courseDropdown)
      expect(await queryByText('Fighting Magneto 202')).toBeInTheDocument()
    })

    it('should render concluded groups in list action container', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select')
      fireEvent.click(courseDropdown)
      expect(await queryByText('concluded_group')).toBeInTheDocument()
    })

    it('should call onCourseFilterSelect when course selected', async () => {
      const mock = jest.fn()

      const component = setup({
        onCourseFilterSelect: mock,
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
        onSelectMailbox: mock,
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
        onSelectMailbox: mock,
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
        activeMailbox: 'sent',
      })

      const mailboxDropdown = await component.findByDisplayValue('Sent')
      expect(mailboxDropdown).toBeTruthy()
    })
  })

  describe('reply buttons', () => {
    it('should disable replying when no conversations are selected', async () => {
      const component = setup({
        selectedConversations: [],
      })

      const replyButton = await component.findByTestId('reply')
      const replyAllButton = await component.findByTestId('reply-all')
      expect(replyButton).toBeDisabled()
      expect(replyAllButton).toBeDisabled()
    })

    it('should enable replying when conversations are selected', async () => {
      const component = setup({
        selectedConversations: [{}],
      })

      const replyButton = await component.findByTestId('reply')
      const replyAllButton = await component.findByTestId('reply-all')
      expect(replyButton).not.toBeDisabled()
      expect(replyAllButton).not.toBeDisabled()
    })

    it('should disable replying when canReply is false', async () => {
      const component = setup({
        selectedConversations: [{}],
        canReply: false,
      })

      const replyButton = await component.findByTestId('reply')
      const replyAllButton = await component.findByTestId('reply-all')
      expect(replyButton).toBeDisabled()
      expect(replyAllButton).toBeDisabled()
    })
  })

  it('should have buttons disabled when their disabled states are true', async () => {
    const component = setup({
      deleteDisabled: true,
      archiveDisabled: true,
    })

    const delBtn = await component.findByTestId('delete')
    const archBtn = await component.findByTestId('archive')
    expect(delBtn).toBeDisabled()
    expect(archBtn).toBeDisabled()
  })

  it('should have buttons enabled when their disabled states are false', async () => {
    const component = setup({
      deleteDisabled: false,
      archiveDisabled: false,
    })

    const delBtn = await component.findByTestId('delete')
    const archBtn = await component.findByTestId('archive')
    expect(delBtn).not.toBeDisabled()
    expect(archBtn).not.toBeDisabled()
  })

  it('should have archive disabled when activeMailbox is sent', async () => {
    const archiveMock = jest.fn()
    const component = setup({
      archiveDisabled: false,
      activeMailbox: 'sent',
      onArchive: archiveMock,
    })

    const archBtn = await component.findByTestId('archive')
    expect(archBtn).toBeDisabled()
  })

  it('should show unarchive button when displayUnarchiveButton is true', async () => {
    const unArchiveMock = jest.fn()
    const component = setup({
      archiveDisabled: false,
      displayUnarchiveButton: true,
      onUnarchive: unArchiveMock,
    })

    const unarchBtn = await component.findByTestId('unarchive')
    expect(unarchBtn).toBeTruthy()
  })

  it('should trigger archive function when unarchiving', async () => {
    const unArchiveMock = jest.fn()
    const component = setup({
      archiveDisabled: false,
      displayUnarchiveButton: true,
      selectedConversations: [{test1: 'test1'}, {test2: 'test2'}],
      onUnarchive: unArchiveMock,
    })

    const unarchBtn = await component.findByTestId('unarchive')
    fireEvent.click(unarchBtn)
    expect(unArchiveMock).toHaveBeenCalled()
  })

  it('should trigger delete function', async () => {
    const deleteMock = jest.fn()
    const component = setup({
      deleteDisabled: false,
      selectedConversations: [{test1: 'test1'}, {test2: 'test2'}],
      onDelete: deleteMock,
    })

    const deleteBtn = await component.findByTestId('delete')
    fireEvent.click(deleteBtn)
    expect(deleteMock).toHaveBeenCalled()
  })
})
