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
    microsoft_sync_login_attribute: 'email',
    microsoft_sync_remote_attribute: 'userPrincipalName',
    microsoft_sync_login_attribute_suffix: '',
  })
}
const defaultDoFetchApiMock = () => {}

// Helpers methods for quickly setting up and fetching things from the test document.
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
    name: /tenant name input area/i,
  })
}

const getLoginAttributeSelector = ({container}) => {
  return container.querySelector('#microsoft_teams_sync_attribute_selector')
}

const getToggle = container => {
  return container.getByRole('checkbox', {
    name: /allows syncing of canvas course members to a microsoft team/i,
  })
}

const getSuffixInput = container => {
  return container.getByRole('textbox', {
    name: /login attribute suffix input area/i,
  })
}

const getLookupFieldSelector = ({container}) => {
  return container.querySelector('#microsoft_teams_sync_remote_attribute_lookup_attribute_selector')
}

describe('MicrosoftSyncAccountSettings', () => {
  beforeEach(() => {
    doFetchApi.mockClear()
    useFetchApi.mockClear()
    window.ENV = {
      MICROSOFT_SYNC: {
        CLIENT_ID: '12345',
        REDIRECT_URI: 'https://www.instructure.com',
        BASE_URL: 'https://login.microsoftonline.com',
      },
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

    it('loads the login attribute selector with the value from the API', () => {
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'sis_user_id',
          microsoft_sync_enabled: true,
        })
      })
      expect(getLoginAttributeSelector(container).title).toMatch(/sis user id/i)
    })

    it('loads the remote login attribute selector with the value from the API', () => {
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_remote_attribute: 'mailNickname',
          microsoft_sync_enabled: true,
        })
      })
      expect(getLookupFieldSelector(container).title).toMatch(/email alias/i)
    })

    it('loads the login attribute suffix with the value from the API', () => {
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute_suffix: '@hello.example.com',
          microsoft_sync_enabled: true,
        })
      })
      expect(getSuffixInput(container).value).toEqual('@hello.example.com')
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
            microsoft_sync_login_attribute: 'email',
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

    it('clears tenant validation error on text change', async () => {
      const container = setup()
      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.com'}})
      fireEvent.click(getUpdateButton(container))
      fireEvent.input(getTextInput(container), {target: {value: 'garbage_input_with_$$.co'}})
      const errMsg = container.queryByText(/please provide a valid tenant domain/i)
      expect(errMsg).not.toBeInTheDocument()
    })

    it("doesn't let the user update settings with a suffix that is too long", async () => {
      const container = setup()

      fireEvent.input(getSuffixInput(container), {
        target: {
          value: 'a'.repeat(256),
        },
      })

      fireEvent.click(getUpdateButton(container))

      const errorMessage = await container.findByText(
        /A suffix cannot be longer than 255 characters\. Please use a shorter suffix and try again\./i
      )

      expect(errorMessage).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it("doesn't let the user update settings with an invalid suffix", async () => {
      const container = setup()

      fireEvent.input(getSuffixInput(container), {
        target: {
          value: '@example.edu\t some extra stuff\n',
        },
      })

      fireEvent.click(getUpdateButton(container))

      const errorMessage = await container.findByText(
        /a suffix cannot have any tabs or spaces\. please remove them and try again\./i
      )

      expect(errorMessage).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it('does let the user update settings with an empty suffix', async () => {
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_enabled: true,
          microsoft_sync_login_attribute: 'sis_user_id',
          microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
        })
      })

      fireEvent.click(getUpdateButton(container))

      expect(
        await container.findByText(/microsoft teams sync settings updated/i)
      ).toBeInTheDocument()
      expect(doFetchApi).toHaveBeenCalledTimes(1)
    })

    it('does not show a Microsoft admin consent link if disabled', () => {
      const container = setup(
        ({loading, success}) => {
          loading(false)
          success({
            microsoft_sync_tenant: 'testtenant.com',
            microsoft_sync_login_attribute: 'sis_user_id',
            microsoft_sync_enabled: false,
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
            microsoft_sync_enabled: true,
          })
        },
        () => {}
      )

      expect(container.queryByText(/Grant tenant access/)).not.toBeInTheDocument()
    })
  })

  describe('typical user interaction', () => {
    it('toggles sync with valid settings', async () => {
      const expectedValues = {
        microsoft_sync_enabled: true,
        microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
        microsoft_sync_login_attribute: 'email',
        microsoft_sync_login_attribute_suffix: '@example.com',
        microsoft_sync_remote_attribute: 'userPrincipalName',
      }
      const container = setup()
      fireEvent.input(getTextInput(container), {
        target: {value: expectedValues.microsoft_sync_tenant},
      })
      fireEvent.input(getSuffixInput(container), {
        target: {value: expectedValues.microsoft_sync_login_attribute_suffix},
      })
      fireEvent.click(getLookupFieldSelector(container))
      fireEvent.click(container.getByText(/user principal name \(upn\)/i))

      fireEvent.click(getToggle(container))

      const success = await container.findByText(/microsoft teams sync settings updated/i)

      const params = doFetchApi.mock.calls.pop()[0]

      expect(getToggle(container)).not.toBeDisabled()
      expect(getUpdateButton(container)).not.toBeDisabled()
      expect(success).toBeInTheDocument()
      expect(params.body.account.settings).toEqual(expectedValues)
    })

    it('updates settings with valid settings', async () => {
      const container = setup()

      fireEvent.input(getTextInput(container), {target: {value: 'canvastest2.onmicrosoft.com'}})
      fireEvent.input(getSuffixInput(container), {target: {value: '@example.com'}})
      fireEvent.click(getLookupFieldSelector(container))
      fireEvent.click(container.getByText(/user principal name \(upn\)/i))

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
          microsoft_sync_enabled: true,
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
          microsoft_sync_enabled: true,
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
          microsoft_sync_enabled: true,
        })
      })
      fireEvent.click(getLoginAttributeSelector(container))
      fireEvent.click(container.getByText(attr))
      fireEvent.click(getToggle(container))
      await waitFor(() => {
        expect(doFetchApi).toHaveBeenCalledTimes(1)
        expect(getLoginAttributeSelector(container).title).toMatch(attr)
      })
    })

    it('lets the user select an Active Directory Lookup Attribute option', async () => {
      const expectedField = /mailNickname/i
      const container = setup(({loading, success}) => {
        loading(false)
        success({
          microsoft_sync_tenant: 'testtenant.com',
          microsoft_sync_login_attribute: 'sis_user_id',
          microsoft_sync_enabled: false,
          microsoft_sync_login_attribute_suffix: '@example.com',
          microsoft_sync_remote_attribute: 'userPrincipalName',
        })
      })

      fireEvent.click(getLookupFieldSelector(container))
      fireEvent.click(container.getByText(expectedField))

      fireEvent.click(getToggle(container))

      await waitFor(() => {
        expect(doFetchApi).toHaveBeenCalledTimes(1)
        expect(getLookupFieldSelector(container).title).toMatch(expectedField)
      })
    })

    it('shows a Microsoft admin consent link', () => {
      const container = setup(
        ({loading, success}) => {
          loading(false)
          success({
            microsoft_sync_tenant: 'testtenant.com',
            microsoft_sync_login_attribute: 'sis_user_id',
            microsoft_sync_enabled: true,
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
