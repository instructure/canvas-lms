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
  SAVE_SETTINGS_FAIL,
} from '../InboxSettingsModalContainer'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {within} from '@testing-library/dom'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import {inboxSettingsHandlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {responsiveQuerySizes} from '../../../../util/utils'
import waitForApolloLoading from '../../../../util/waitForApolloLoading'
import MockDate from 'mockdate'
import moment from 'moment-timezone'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('InboxSettingsModalContainer', () => {
  const server = mswServer(inboxSettingsHandlers())
  let onDismissWithAlertMock
  const oldLocale = moment.locale()

  const defaultProps = (props = {}) => ({
    inboxSignatureBlock: true,
    inboxAutoResponse: true,
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
    MockDate.set('2024-04-22T00:00:00-07:00', 0)
    moment.locale('en-us')
  })

  afterEach(() => {
    server.resetHandlers()
    jest.clearAllMocks()
    MockDate.reset()
    moment.locale(oldLocale)
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({
    inboxSignatureBlock = true,
    inboxAutoResponse = true,
    onDismissWithAlert = onDismissWithAlertMock,
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <InboxSettingsModalContainer
            inboxSignatureBlock={inboxSignatureBlock}
            inboxAutoResponse={inboxAutoResponse}
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
      const {getAllByText} = setup({...defaultProps()})
      expect(getAllByText('Loading Inbox Settings').length).toBe(2)
    })

    it('shows modal', async () => {
      const {queryByText} = setup({...defaultProps()})
      await waitForApolloLoading()
      expect(queryByText('Inbox Settings')).toBeInTheDocument()
    })

    it('calls onDismissWithAlert on Cancel button click', async () => {
      const {getByText} = setup({...defaultProps()})
      await waitForApolloLoading()
      fireEvent.click(getByText('Cancel'))
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('calls onDismissWithAlert on Close (X) button click', async () => {
      const {getByRole} = setup({...defaultProps()})
      await waitForApolloLoading()
      fireEvent.click(within(getByRole('dialog')).getByText('Close'))
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_OK when GraphQL mutation succeeds', async () => {
      const {getByText} = setup({...defaultProps()})
      await waitForApolloLoading()
      fireEvent.click(getByText('Save'))
      await waitForApolloLoading()
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_OK)
      })
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_FAIL when GraphQL mutation fails', async () => {
      server.use(...inboxSettingsHandlers(1))
      const {getByText} = setup({...defaultProps()})
      await waitForApolloLoading()
      fireEvent.click(getByText('Save'))
      await waitForApolloLoading()
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_FAIL)
      })
    })

    describe('when useSignature gets enabled', () => {
      it('shows error if signature > 255 characters', async () => {
        const {getByText, getByLabelText, getByTestId} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Signature On')))
        fireEvent.change(getByTestId('inbox-signature-input'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })
    })

    describe('when useOutOfOffice gets enabled', () => {
      it('shows error on Save button click if start and/or end dates are in the past', async () => {
        const {getByText, getAllByText, getByLabelText} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Response On')))
        fireEvent.click(getByLabelText(new RegExp('Start Date')))
        fireEvent.click(getByText('15').closest('button'))
        fireEvent.click(getByLabelText(new RegExp('End Date')))
        fireEvent.click(getByText('16').closest('button'))
        await waitFor(() => {
          fireEvent.click(getByText('Save'))
          expect(getAllByText('Date cannot be in the past').length).toBe(2)
        })
      })

      it('shows error on Save button click if end date is before start date', async () => {
        const {getByText, getByLabelText} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Response On')))
        fireEvent.click(getByLabelText(new RegExp('End Date')))
        fireEvent.click(getByText('15').closest('button'))
        await waitFor(() => {
          fireEvent.click(getByText('Save'))
          expect(getByText('Date cannot be before start date')).toBeInTheDocument()
        })
      })

      it('shows error if message > 255 characters', async () => {
        const {getByText, getByLabelText} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Response On')))
        fireEvent.change(getByLabelText('Message'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })

      it('shows error if subject > 255 characters', async () => {
        const {getByText, getByLabelText, getByTestId} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Response On')))
        fireEvent.change(getByTestId('out-of-office-subject-input'), {
          target: {value: 'a'.repeat(256)},
        })
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })
    })

    describe('when useOutOfOffice is previously enabled', () => {
      beforeEach(() => {
        server.use(...inboxSettingsHandlers(2))
      })

      it('does not validate dates on Save button click if OOO settings unchanged', async () => {
        const {getByText, queryByText} = setup({...defaultProps()})
        await waitFor(() => {
          fireEvent.click(getByText('Save'))
          expect(queryByText('Date cannot be in the past')).not.toBeInTheDocument()
        })
      })

      it('validates dates on Save button click if OOO settings get changed', async () => {
        const {getByText, getByLabelText} = setup({...defaultProps()})
        await waitForApolloLoading()
        fireEvent.click(getByLabelText(new RegExp('Start Date')))
        fireEvent.click(getByText('15').closest('button'))
        await waitFor(() => {
          fireEvent.click(getByText('Save'))
          expect(getByText('Date cannot be in the past')).toBeInTheDocument()
        })
      })
    })
  })

  it('displays signature and auto response settings when inboxSignatureBlock and inboxAutoResponse props are true', async () => {
    const {getByText} = setup({...defaultProps()})
    await waitFor(() => {
      expect(getByText('Signature*')).toBeInTheDocument()
      expect(getByText('Out of Office')).toBeInTheDocument()
    })
  })

  it('displays only signature settings when only inboxSignatureBlock prop is true', async () => {
    const {getByText, queryByText} = setup({
      ...defaultProps({
        inboxSignatureBlock: true,
        inboxAutoResponse: false,
      }),
    })
    await waitFor(() => {
      expect(getByText('Signature*')).toBeInTheDocument()
      expect(queryByText('Out of Office')).not.toBeInTheDocument()
    })
  })

  it('displays only auto response settings when only inboxAutoResponse prop is true', async () => {
    const {getByText, queryByText} = setup({
      ...defaultProps({
        inboxSignatureBlock: false,
        inboxAutoResponse: true,
      }),
    })
    await waitFor(() => {
      expect(queryByText('Add Signature*')).not.toBeInTheDocument()
      expect(getByText('Out of Office')).toBeInTheDocument()
    })
  })
})
