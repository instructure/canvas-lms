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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {within} from '@testing-library/dom'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import {inboxSettingsHandlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '@canvas/msw/mswClient'
import {setupServer} from 'msw/node'
import MockDate from 'mockdate'
import moment from 'moment-timezone'

vi.mock('../../../../util/utils', async () => {
  const actual = await vi.importActual('../../../../util/utils')
  return {
    ...actual,
    responsiveQuerySizes: vi.fn(),
  }
})

const {responsiveQuerySizes} = await import('../../../../util/utils')

describe('InboxSettingsModalContainer', () => {
  const server = setupServer(...inboxSettingsHandlers())
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
    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'},
    }))
  })

  beforeEach(() => {
    onDismissWithAlertMock = vi.fn()
    mswClient.cache.reset()
    MockDate.set('2024-04-22T00:00:00-07:00', 0)
    moment.locale('en-us')
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
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
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
          <InboxSettingsModalContainer
            inboxSignatureBlock={inboxSignatureBlock}
            inboxAutoResponse={inboxAutoResponse}
            onDismissWithAlert={onDismissWithAlert}
          />
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

  // fickle
  describe('InboxSettingsModalContainer (2)', () => {
    it('should render', async () => {
      const container = setup()
      expect(container).toBeTruthy()
    })

    it('shows loader for inbox settings', async () => {
      const {getAllByText} = setup({...defaultProps()})
      expect(getAllByText('Loading Inbox Settings')).toHaveLength(2)
    })

    it('shows modal', async () => {
      const {findByText} = setup({...defaultProps()})
      expect(await findByText('Inbox Settings')).toBeInTheDocument()
    })

    it('calls onDismissWithAlert on Cancel button click', async () => {
      const {findByText} = setup({...defaultProps()})
      const cancelButton = await findByText('Cancel')
      fireEvent.click(cancelButton)
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('calls onDismissWithAlert on Close (X) button click', async () => {
      const {getByRole, findByTestId} = setup({...defaultProps()})
      await findByTestId('inbox-signature-input')
      fireEvent.click(within(getByRole('dialog')).getByText('Close'))
      await waitFor(() => {
        expect(onDismissWithAlertMock).toHaveBeenCalledTimes(1)
      })
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_OK when GraphQL mutation succeeds', async () => {
      const {findByText, findByTestId} = setup({...defaultProps()})
      await findByTestId('inbox-signature-input')
      fireEvent.click(await findByText('Save'))
      await waitFor(
        () => {
          expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_OK)
        },
        {timeout: 5000},
      )
    })

    it('calls onDismissWithAlert with SAVE_SETTINGS_FAIL when GraphQL mutation fails', async () => {
      server.use(...inboxSettingsHandlers(1))
      const {findByText, findByTestId} = setup({...defaultProps()})
      await findByTestId('inbox-signature-input')
      fireEvent.click(await findByText('Save'))
      await waitFor(
        () => {
          expect(onDismissWithAlertMock).toHaveBeenCalledWith(SAVE_SETTINGS_FAIL)
        },
        {timeout: 5000},
      )
    })

    describe('when useSignature gets enabled', () => {
      it('shows error if signature > 255 characters', async () => {
        const {findByText, findByLabelText, findByTestId} = setup({...defaultProps()})
        const signatureInput = await findByTestId('inbox-signature-input')
        fireEvent.click(await findByLabelText(new RegExp('Signature On')))
        fireEvent.change(signatureInput, {target: {value: 'a'.repeat(256)}})
        expect(await findByText('Must be 255 characters or less')).toBeInTheDocument()
      })
    })

    describe('when useOutOfOffice gets enabled', () => {
      // TODO: These date picker tests are skipped due to DateInput2 calendar interaction
      // issues after Jest-to-Vitest migration. DateInput2 requires a complex interaction
      // pattern (click -> tab -> space) that doesn't work reliably with the current test setup.
      // See: DateInput2.test.jsx for the expected interaction pattern.
      it.skip('shows error on Save button click if start and/or end dates are in the past', async () => {
        const user = userEvent.setup()
        const {getAllByText, findByLabelText, findByText} = setup({...defaultProps()})
        const responseOn = await findByLabelText(new RegExp('Response On'))
        await user.click(responseOn)

        // Open start date picker: click input, tab to icon, press space
        const startDateInput = await findByLabelText(new RegExp('Start Date'))
        await user.click(startDateInput)
        await user.tab()
        await user.keyboard('[Space]')
        await waitFor(() => expect(screen.getByText('15')).toBeInTheDocument(), {timeout: 3000})
        await user.click(screen.getByText('15').closest('button'))

        // Open end date picker
        const endDateInput = await findByLabelText(new RegExp('End Date'))
        await user.click(endDateInput)
        await user.tab()
        await user.keyboard('[Space]')
        await waitFor(() => expect(screen.getByText('16')).toBeInTheDocument(), {timeout: 3000})
        await user.click(screen.getByText('16').closest('button'))

        await user.click(await findByText('Save'))
        await waitFor(() => {
          expect(getAllByText('Date cannot be in the past')).toHaveLength(2)
        })
      })

      it.skip('shows error on Save button click if end date is before start date', async () => {
        const user = userEvent.setup()
        const {findByLabelText, findByText} = setup({...defaultProps()})

        // Enable out of office response
        const responseToggle = await findByLabelText(new RegExp('Response On'))
        await user.click(responseToggle)

        // Set end date first (April 15)
        const endDateInput = await findByLabelText(new RegExp('End Date'))
        await user.click(endDateInput)
        await user.tab()
        await user.keyboard('[Space]')
        await waitFor(() => expect(screen.getByText('15')).toBeInTheDocument(), {timeout: 3000})
        await user.click(screen.getByText('15').closest('button'))

        // Set start date later (April 16)
        const startDateInput = await findByLabelText(new RegExp('Start Date'))
        await user.click(startDateInput)
        await user.tab()
        await user.keyboard('[Space]')
        await waitFor(() => expect(screen.getByText('16')).toBeInTheDocument(), {timeout: 3000})
        await user.click(screen.getByText('16').closest('button'))

        // Click save and wait for validation
        await user.click(await findByText('Save'))

        // Wait for validation message
        await waitFor(() => {
          expect(screen.getByText('Date cannot be before start date')).toBeInTheDocument()
        })
      })

      it('shows error if message > 255 characters', async () => {
        const {findByText, findByLabelText} = setup({...defaultProps()})
        await findByLabelText(new RegExp('Response On'))
        fireEvent.click(await findByLabelText(new RegExp('Response On')))
        fireEvent.change(await findByLabelText('Message'), {target: {value: 'a'.repeat(256)}})
        expect(await findByText('Must be 255 characters or less')).toBeInTheDocument()
      })

      it('shows error if subject > 255 characters', async () => {
        const {findByText, findByLabelText, findByTestId} = setup({...defaultProps()})
        await findByTestId('out-of-office-subject-input')
        fireEvent.click(await findByLabelText(new RegExp('Response On')))
        fireEvent.change(await findByTestId('out-of-office-subject-input'), {
          target: {value: 'a'.repeat(256)},
        })
        expect(await findByText('Must be 255 characters or less')).toBeInTheDocument()
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

      // TODO: This date picker test is skipped due to DateInput2 calendar interaction
      // issues after Jest-to-Vitest migration. See comment above for details.
      it.skip('validates dates on Save button click if OOO settings get changed', async () => {
        const user = userEvent.setup()
        const {findByLabelText, findByText} = setup({...defaultProps()})
        const startDateInput = await findByLabelText(new RegExp('Start Date'))
        await user.click(startDateInput)
        await user.tab()
        await user.keyboard('[Space]')
        await waitFor(() => expect(screen.getByText('15')).toBeInTheDocument(), {timeout: 3000})
        await user.click(screen.getByText('15').closest('button'))
        await user.click(await findByText('Save'))
        await waitFor(() => {
          expect(screen.getByText('Date cannot be in the past')).toBeInTheDocument()
        })
      })
    })
  })

  it('displays signature and auto response settings when inboxSignatureBlock and inboxAutoResponse props are true', async () => {
    const {getByText, getByTestId} = setup({...defaultProps()})
    await waitFor(() => {
      expect(getByTestId('inbox-signature-input')).toHaveValue('My signature')
      expect(getByText('Out of Office')).toBeInTheDocument()
    })
  })

  it('displays only signature settings when only inboxSignatureBlock prop is true', async () => {
    const {queryByText, getByTestId} = setup({
      ...defaultProps({
        inboxSignatureBlock: true,
        inboxAutoResponse: false,
      }),
    })
    await waitFor(() => {
      expect(getByTestId('inbox-signature-input')).toHaveValue('My signature')
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
