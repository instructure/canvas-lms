/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute and/or modify under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {render, screen} from '@testing-library/react'
import DeveloperKeyFormFields from '../NewKeyForm'
import fakeENV from '@canvas/test-utils/fakeENV'

import type {DeveloperKey} from 'features/developer_keys_v2/model/api/DeveloperKey'
import type {NewKeyFormProps} from '../NewKeyForm'

const developerKey: DeveloperKey = {
  access_token_count: 77,
  account_name: 'bob account',
  api_key: 'rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3',
  created_at: '2018-02-09T20:36:50Z',
  email: 'bob@myemail.com',
  icon_url: 'http://my_image.com',
  id: '10000000000004',
  name: 'Atomic fireball',
  notes: 'all the notas',
  redirect_uri: 'http://my_redirect_uri.com',
  redirect_uris: 'http://another.redirect.com\nhttp://another.one.com',
  vendor_code: 'b3w9w9bf',
  test_cluster_only: false,
  allow_includes: false,
  scopes: [],
  require_scopes: null,
  tool_configuration: null,
  client_credentials_audience: null,
  is_lti_key: false,
  is_lti_registration: false,
}

function defaultProps(): NewKeyFormProps {
  return {
    availableScopes: {},
    availableScopesPending: false,
    dispatch: () => {},
    listDeveloperKeyScopesSet: () => {},
    editing: false,
    tool_configuration: {
      oidc_initiation_url: undefined,
    },
    showRequiredMessages: false,
    showMissingRedirectUrisMessage: undefined,
    updateToolConfiguration: () => {},
    updateToolConfigurationUrl: () => {},
    updateDeveloperKey: () => {},
    toolConfigurationUrl: null,
    configurationMethod: '',
    updateConfigurationMethod: () => {},
    hasRedirectUris: false,
    syncRedirectUris: () => {},
    isRedirectUriRequired: false,
    isLtiKey: false,
    hasInvalidRedirectUris: false,
    developerKey: {
      access_token_count: 0,
      account_name: '',
      api_key: '',
      created_at: '',
      email: '',
      icon_url: '',
      id: '',
      name: '',
      notes: '',
      redirect_uri: '',
      redirect_uris: '',
      vendor_code: '',
      test_cluster_only: false,
      allow_includes: false,
      scopes: [],
      require_scopes: null,
      tool_configuration: null,
      client_credentials_audience: null,
      is_lti_key: false,
      is_lti_registration: false,
    },
  }
}

function renderComponent(
  devKey: DeveloperKey,
  isLtiKey: boolean,
  extraProps: Partial<NewKeyFormProps> = {},
) {
  const props = {...defaultProps(), developerKey: devKey, isLtiKey, ...extraProps}
  return render(<DeveloperKeyFormFields {...props} />)
}

describe('DeveloperKeyFormFields', () => {
  beforeEach(() => {
    fakeENV.setup({
      validLtiPlacements: ['course_navigation', 'account_navigation'],
      validLtiScopes: {},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('populates the key name', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const input = getByTestId('key-name-input')
    expect(input).toHaveValue(developerKey.name)
  })

  it('populates the key owner email', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const input = getByTestId('owner-email-input')
    expect(input).toHaveValue(developerKey.email)
  })

  it('populates the key legacy redirect uri', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const input = getByTestId('legacy-redirect-uri-input')
    expect(input).toHaveValue(developerKey.redirect_uri)
  })

  it('populates the key redirect uris', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const textarea = getByTestId('redirect-uris-input')
    expect(textarea).toHaveValue(developerKey.redirect_uris)
  })

  it('populates the key vendor code', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const input = getByTestId('vendor-code-input')
    expect(input).toHaveValue(developerKey.vendor_code)
  })

  it('populates the key icon URL', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const input = getByTestId('icon-url-input')
    expect(input).toHaveValue(developerKey.icon_url)
  })

  it('populates the key notes', () => {
    const {getByTestId} = renderComponent(developerKey, false)
    const textarea = getByTestId('notes-input')
    expect(textarea).toHaveValue(developerKey.notes)
  })

  it('does not populate the key test_cluster_only without ENV set', () => {
    const {queryByTestId} = renderComponent(developerKey, false)
    expect(queryByTestId('test-cluster-only-checkbox')).not.toBeInTheDocument()
  })

  it('populates the key test_cluster_only when ENV is set', () => {
    fakeENV.setup({
      ...window.ENV,
      enableTestClusterChecks: true,
    })
    const {getByTestId} = renderComponent(developerKey, false)
    const checkbox = getByTestId('test-cluster-only-checkbox')
    expect(checkbox).toBeInTheDocument()
    expect(checkbox).not.toBeChecked()
  })

  describe('when isLtiKey is true', () => {
    it('does not include legacy redirect uri', () => {
      const {queryByTestId} = renderComponent(developerKey, true)
      expect(queryByTestId('legacy-redirect-uri-input')).not.toBeInTheDocument()
    })

    it('does not include vendor code', () => {
      const {queryByTestId} = renderComponent(developerKey, true)
      expect(queryByTestId('vendor-code-input')).not.toBeInTheDocument()
    })

    it('does not include icon URL', () => {
      const {queryByTestId} = renderComponent(developerKey, true)
      expect(queryByTestId('icon-url-input')).not.toBeInTheDocument()
    })

    it('includes redirect uris', () => {
      const {getByTestId} = renderComponent(developerKey, true)
      expect(getByTestId('redirect-uris-input')).toBeInTheDocument()
    })

    it('includes key name', () => {
      const {getByTestId} = renderComponent(developerKey, true)
      const input = getByTestId('key-name-input')
      expect(input).toHaveValue(developerKey.name)
    })

    it('includes owner email', () => {
      const {getByTestId} = renderComponent(developerKey, true)
      const input = getByTestId('owner-email-input')
      expect(input).toHaveValue(developerKey.email)
    })

    it('includes notes', () => {
      const {getByTestId} = renderComponent(developerKey, true)
      const textarea = getByTestId('notes-input')
      expect(textarea).toHaveValue(developerKey.notes)
    })

    it('renders the tool configuration form', () => {
      const {getByText, getByRole} = renderComponent(developerKey, true)
      expect(getByText('Developer Key Settings')).toBeInTheDocument()
      expect(getByRole('combobox', {name: /method/i})).toBeInTheDocument()
    })
  })

  describe('when isLtiKey is false', () => {
    it('renders the developer key scopes form', () => {
      const {getByTestId, getByText} = renderComponent(developerKey, false)
      const enforceScopes = document.querySelector('[data-automation="enforce_scopes"]')
      expect(enforceScopes).toBeInTheDocument()
      expect(getByText(/when scope enforcement is disabled/i)).toBeInTheDocument()
    })
  })

  describe('redirect URIs field', () => {
    it('renders as optional when isRedirectUriRequired is false', () => {
      const {getByText, queryByText} = renderComponent(developerKey, true, {
        isRedirectUriRequired: false,
      })
      expect(getByText('Redirect URIs:')).toBeInTheDocument()
      expect(queryByText('Redirect URIs: *')).not.toBeInTheDocument()
    })

    it('renders as required when isRedirectUriRequired is true', () => {
      const {getByText} = renderComponent(developerKey, true, {isRedirectUriRequired: true})
      expect(screen.getByLabelText('Redirect URIs: *')).toBeInTheDocument()
    })
  })
})
