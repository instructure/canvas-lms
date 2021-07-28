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

import {fireEvent, render, waitFor} from '@testing-library/react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import React from 'react'
import MicrosoftSyncAccountSettings from '../MicrosoftSyncAccountSettings'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/use-fetch-api-hook')
jest.mock('@canvas/do-fetch-api-effect')

const defaultUseFetchMock = ({loading, success}) => {
  loading(false)
  success({
    microsoft_sync_enabled: false,
    microsoft_sync_tenant: '',
    microsoft_sync_login_attribute: 'email'
  })
}
const defaultDoFetchApiMock = () => {}

const setup = (useFetchApiMock = defaultUseFetchMock, doFetchApiMock = defaultDoFetchApiMock) => {
  doFetchApi.mockImplementation(doFetchApiMock)
  useFetchApi.mockImplementationOnce(useFetchApiMock)
  return render(<MicrosoftSyncAccountSettings />)
}

const getUpdateButton = container => {
  return container.getByText(/update settings/i).closest('button')
}
const getTextInput = container => {
  return container.getByRole('textbox', {
    name: /tenant name input area/i
  })
}
const getToggle = container => {
  return container.getByRole('checkbox', {
    name: /allows syncing of canvas course members to a microsoft team/i
  })
}

describe('MicrosoftSyncAccountSettings', () => {
  beforeEach(() => {
    doFetchApi.mockClear()
    useFetchApi.mockClear()
    window.ENV = {
      MICROSOFT_SYNC: {
        CLIENT_ID: '12345',
        REDIRECT_URI: 'https://www.instructure.com',
        BASE_URL: 'https://login.microsoftonline.com'
      }
    }
  })

  afterEach(() => {
    window.ENV = {}
  })

  describe('basic rendering tests', () => {
    it('renders a spinner when loading', () => {
      const container = setup(({loading}) => loading(true))

      expect(container.getByText(/Loading Microsoft Teams Sync settings/i)).toBeInTheDocument()
    })

    it("doesn't render the spinner when not loading", () => {
      const container = setup()

      expect(
        container.queryByText(/Loading Microsoft Teams Sync settings/i)
      ).not.toBeInTheDocument()
    })

    it('renders without errors', () => {
      const container = setup()

      expect(container).toBeTruthy()
      expect(container.error).toBeFalsy()
    })
  })

  describe('error handling', () => {
    it('displays an error message when it fails to fetch settings', () => {
      const container = setup(({loading, error}) => {
        loading(false)
        error('fetch failed')
      })

      expect(
        container.getByText(/Unable to fetch current Microsoft Teams Sync settings/i)
      ).toBeInTheDocument()
    })

    it('informs the user if it was unable to toggle sync', async () => {
      const container = setup(
        ({success, loading}) => {
          loading(false)
          success({
            microsoft_sync_enabled: false,
            microsoft_sync_tenant: 'testtenant.com',
            microsoft_sync_login_attribute: 'email'
          })
        },
        () => {
          throw new Error('test failure!')
        }
      )

      fireEvent.click(getToggle(container))

      const errMsg = await container.findByText(
        /Unable to update Microsoft Teams Sync settings. Please try again. If the issue persists, please contact support/i
      )
      expect(errMsg).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(getToggle(container)).not.toBeChecked()
      expect(
        container.queryByText('Microsoft Teams Sync settings updated!')
      ).not.toBeInTheDocument()
    })
  })

  describe('client-side validation', () => {
    it("doesn't let a user enable sync without a tenant", async () => {
      const container = setup()

      fireEvent.click(getToggle(container))

      const errMsg = await container.findByText(
        /to toggle microsoft teams sync you need to input a tenant domain\./i
      )
      expect(errMsg).toBeInTheDocument()
      expect(getToggle(container)).not.toBeChecked()
    })

    it("doesn't let the user enable sync without a valid tenant", async () => {
      const container = setup()

      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.com'}})
      fireEvent.click(getToggle(container))
      const errMsg = await container.findByText(/Please provide a valid tenant domain/i)
      expect(errMsg).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it("doesn't let the user update settings with a blank tenant", async () => {
      const container = setup()

      fireEvent.click(getUpdateButton(container))

      const errorMessage = await container.findByText(
        /to toggle microsoft teams sync you need to input a tenant domain/i
      )
      expect(errorMessage).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it("doesn't let the user update settings without a valid tenant", async () => {
      const container = setup()
      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.com'}})

      fireEvent.click(getUpdateButton(container))

      const errMsg = await container.findByText(/please provide a valid tenant domain/i)
      expect(errMsg).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it('clears validation error on text change', async () => {
      const container = setup()
      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.com'}})
      fireEvent.click(getUpdateButton(container))
      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.co'}})
      const errMsg = container.queryByText(/please provide a valid tenant domain/i)
      expect(errMsg).not.toBeInTheDocument()
    })

    it('does not show a Microsoft admin consent link if disabled', () => {
      const container = setup(
        ({loading, success}) => {
          loading(false)
          success({
            microsoft_sync_tenant: 'testtenant.com',
            microsoft_sync_login_attribute: 'sis_user_id',
            microsoft_sync_enabled: false
          })
        },
        () => {}
      )

      expect(container.queryByText(/Grant tenant access/)).not.toBeInTheDocument()
    })

    it('does not show a Microsoft admin consent link if tenant empty', () => {
      const container = setup(
        ({loading, success}) => {
          loading(false)
          success({
            microsoft_sync_tenant: '',
            microsoft_sync_login_attribute: 'sis_user_id',
            microsoft_sync_enabled: true
          })
        },
        () => {}
      )

      expect(container.queryByText(/Grant tenant access/)).not.toBeInTheDocument()
    })
  })

  describe('typical user interaction', () => {
    it('toggles sync with a valid tenant and login attribute', async () => {
      const container = setup()
      fireEvent.input(getTextInput(container), {target: {value: 'canvastest2.onmicrosoft.com'}})

      fireEvent.click(getToggle(container))

      const success = await container.findByText(/microsoft teams sync settings updated/i)

      expect(getToggle(container)).not.toBeDisabled()
      expect(getUpdateButton(container)).not.toBeDisabled()
      expect(success).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(1)
    })

    it('updates settings with a valid settings', async () => {
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'email',
          microsoft_sync_enabled: true
        })
      })

      fireEvent.click(getUpdateButton(container))

      const success = await container.findByText(/microsoft teams sync settings updated/i)
      expect(getToggle(container)).not.toBeDisabled()
      expect(getUpdateButton(container)).not.toBeDisabled()
      expect(success).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(1)
    })

    it('disables the UI when updating settings', () => {
      const stallNetwork = () => {
        return new Promise(() => {})
      }
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'email',
          microsoft_sync_enabled: true
        })
      }, stallNetwork)
      fireEvent.click(getUpdateButton(container))

      expect(getToggle(container)).toBeDisabled()
      expect(getUpdateButton(container)).toBeDisabled()
    })

    it('disables the UI when toggling sync', () => {
      const stallNetwork = () => {
        return new Promise(() => {})
      }
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'email',
          microsoft_sync_enabled: true
        })
      }, stallNetwork)
      fireEvent.click(getToggle(container))

      expect(getToggle(container)).toBeDisabled()
      expect(getUpdateButton(container)).toBeDisabled()
    })

    it('lets the user select a login attribute', async () => {
      const attr = /email/i
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'sis_user_id',
          microsoft_sync_enabled: true
        })
      })
      fireEvent.click(container.getByRole('button', {name: /login attribute selector/i}))
      fireEvent.click(container.getByText(attr))
      fireEvent.click(getToggle(container))
      await waitFor(() => {
        expect(doFetchApi).toHaveBeenCalledTimes(1)
        expect(container.getByRole('button', {name: /login attribute selector/i}).title).toMatch(
          attr
        )
      })
    })

    it('shows a Microsoft admin consent link', () => {
      const container = setup(
        ({loading, success}) => {
          loading(false)
          success({
            microsoft_sync_tenant: 'testtenant.com',
            microsoft_sync_login_attribute: 'sis_user_id',
            microsoft_sync_enabled: true
          })
        },
        () => {}
      )

      const anchorTag = container.getByText(/Grant tenant access/)
      expect(anchorTag.href).toEqual(
        'https://login.microsoftonline.com/testtenant.com/adminconsent?client_id=12345&redirect_uri=https%3A%2F%2Fwww.instructure.com'
      )
    })
  })
})
