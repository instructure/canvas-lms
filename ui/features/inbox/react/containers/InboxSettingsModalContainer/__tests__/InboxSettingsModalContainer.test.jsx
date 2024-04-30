/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import InboxSettingsModalContainer, {
  SAVE_SETTINGS_OK,
  SAVE_SETTINGS_FAIL
} from '../InboxSettingsModalContainer'
import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {within} from '@testing-library/dom'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import {inboxSettingsHandlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {responsiveQuerySizes} from '../../../../util/utils'
import waitForApolloLoading from '../../../../util/waitForApolloLoading'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

const USER_EVENT_OPTIONS = {delay: null, pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('InboxSettingsModalContainer', () => {
  const server = mswServer(inboxSettingsHandlers())
  let onDismissWithAlertMock

  const defaultProps = (props = {}) => ({
    open: true,
    onDismissWithAlert: onDismissWithAlertMock,
    ...props,
  })

  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  beforeEach(() => {
    onDismissWithAlertMock = jest.fn()
    mswClient.cache.reset()
  })

  afterEach(() => {
    server.resetHandlers()
    jest.clearAllMocks()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({
    open = true,
    onDismissWithAlert = onDismissWithAlertMock
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <InboxSettingsModalContainer
            open={open}
            onDismissWithAlert={onDismissWithAlert}
          />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )

  describe('InboxSettingsModalContainer', () => {
    it('should render', async () => {
      const container = setup()
      expect(container).toBeTruthy()
    })

    it('shows loader for inbox settings', async () => {
      const {getByText} = setup({...defaultProps()})
      expect(getByText('Loading Inbox Settings')).toBeInTheDocument()
    })

    it('shows modal', async () => {
      const container = setup({...defaultProps()})
      await waitForApolloLoading()
      expect(container.queryByText('Inbox Settings')).toBeInTheDocument()
    })

    it('calls onDismissWithAlert on Cancel button click', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText} = setup({...defaultProps()})
      await waitFor(() => {
        user.click(getByText('Cancel'))
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('calls onDismissWithAlert on Close (X) button click', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByRole} = setup({...defaultProps()})
      await waitFor(() => {
        user.click(within(getByRole('dialog')).getByText('Close'))
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('shows error message below textarea if signature > 255 characters', async () => {
      const {getByText, getByLabelText} = setup({...defaultProps()})
      await waitFor(() => {
        fireEvent.change(getByLabelText('Signature'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_OK when GraphQL mutation succeeds', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const component = setup({...defaultProps()})
      await waitForApolloLoading()
      const signature = component.getByLabelText('Signature')
      fireEvent.change(signature, {target: {value: 'John Doe'}})
      user.click(component.getByText('Save'))
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_OK)
      })
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_FAIL when GraphQL mutation fails', async () => {
      server.use(...inboxSettingsHandlers(1))
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const component = setup({...defaultProps()})
      await waitForApolloLoading()
      const signature = component.getByLabelText('Signature')
      fireEvent.change(signature, {target: {value: 'John Doe'}})
      user.click(component.getByText('Save'))
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_FAIL)
      })
    })
  })
})
