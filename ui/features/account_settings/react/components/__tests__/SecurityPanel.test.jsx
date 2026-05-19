/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {SecurityPanel} from '../SecurityPanel'

const defaultProps = {
  context: 'account',
  contextId: '1',
  maxDomains: 50,
}

const cspSettingsResponse = {
  enabled: false,
  inherited: false,
  effective_whitelist: [],
  current_account_whitelist: [],
  tools_whitelist: {},
}

const server = setupServer(
  http.get('/api/v1/accounts/1/csp_settings', () => HttpResponse.json(cspSettingsResponse)),
)

describe('SecurityPanel', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    window.ENV = {ACCOUNT: {id: '1234'}}
  })

  afterEach(() => server.resetHandlers())

  it('updates CSP enabled status when the checkbox is clicked', async () => {
    server.use(
      http.put('/api/v1/accounts/1/csp_settings', () => HttpResponse.json({enabled: true})),
    )

    const {getByLabelText} = render(<SecurityPanel {...defaultProps} />)

    await waitFor(() => {
      expect(getByLabelText('Enable Content Security Policy')).toBeInTheDocument()
    })
    const checkbox = getByLabelText('Enable Content Security Policy')
    fireEvent.click(checkbox)
    await waitFor(() => {
      expect(checkbox.checked).toBeTruthy()
    })
  })

  describe('isSubAccount prop', () => {
    it('updates CSP inherited status when the inherit checkbox is clicked', async () => {
      server.use(
        http.put('/api/v1/accounts/1/csp_settings', () =>
          HttpResponse.json({
            inherited: true,
            enabled: false,
            effective_whitelist: [],
            current_account_whitelist: [],
            tools_whitelist: {},
          }),
        ),
      )

      const {getByLabelText} = render(<SecurityPanel {...defaultProps} isSubAccount={true} />)

      await waitFor(() => {
        expect(getByLabelText('Inherit Content Security Policy')).toBeInTheDocument()
      })
      const checkbox = getByLabelText('Inherit Content Security Policy')
      fireEvent.click(checkbox)
      await waitFor(() => {
        expect(checkbox.checked).toBeTruthy()
      })
    })

    it('disables the enable checkbox when the inherit option is set to true', async () => {
      server.use(
        http.put('/api/v1/accounts/1/csp_settings', () =>
          HttpResponse.json({
            inherited: true,
            enabled: false,
            effective_whitelist: [],
            current_account_whitelist: [],
            tools_whitelist: {},
          }),
        ),
      )

      const {getByLabelText} = render(<SecurityPanel {...defaultProps} isSubAccount={true} />)

      await waitFor(() => {
        expect(getByLabelText('Inherit Content Security Policy')).toBeInTheDocument()
      })

      const checkbox = getByLabelText('Inherit Content Security Policy')
      fireEvent.click(checkbox)
      await waitFor(() => {
        expect(checkbox.checked).toBeTruthy()
      })

      const enableCheckbox = getByLabelText('Enable Content Security Policy')
      expect(enableCheckbox).toBeDisabled()
    })
  })
})
