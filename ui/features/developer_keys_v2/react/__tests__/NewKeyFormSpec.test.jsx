/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import DeveloperKeyFormFields from '../NewKeyForm'
import {render} from '@testing-library/react'

describe('NewKeyForm', () => {
  const developerKey = {
    access_token_count: 77,
    account_name: 'bob account',
    api_key: 'rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3',
    created_at: '2018-02-09T20:36:50Z',
    email: 'bob@myemail.com',
    icon_url: 'http://my_image.com',
    id: '10000000000004',
    last_used_at: '2018-06-07T20:36:50Z',
    name: 'Atomic fireball',
    notes: 'all the notas',
    redirect_uri: 'http://my_redirect_uri.com',
    redirect_uris: 'http://another.redirect.com\nhttp://another.one.com',
    user_id: '53532',
    user_name: 'billy bob',
    vendor_code: 'b3w9w9bf',
    workflow_state: 'active',
    test_cluster_only: true,
  }

  function formFieldOfTypeAndName(devKey, fieldType, name, isLtiKey, env = {}) {
    window.ENV = {
      validLtiPlacements: [],
      validLtiScopes: {},
      ...env,
    }

    const component = TestUtils.renderIntoDocument(
      <DeveloperKeyFormFields
        availableScopes={{}}
        availableScopesPending={false}
        developerKey={devKey}
        dispatch={() => {}}
        listDeveloperKeyScopesSet={() => {}}
        updateToolConfigurationUrl={() => {}}
        updateConfigurationMethod={() => {}}
        updateDeveloperKey={() => {}}
        showRequiredMessages={false}
        editing={false}
        tool_configuration={{}}
        configurationMethod="json"
        validPlacements={{}}
        isLtiKey={isLtiKey}
      />
    )
    return TestUtils.scryRenderedDOMComponentsWithTag(component, fieldType).find(
      elem => elem.name === `developer_key[${name}]`
    )
  }

  test('populates the key name', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'name')
    expect(input.value).toEqual(developerKey.name)
  })

  test('populates the key owner email', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'email')
    expect(input.value).toEqual(developerKey.email)
  })

  test('populates the key legacy redirect uri', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'redirect_uri')
    expect(input.value).toEqual(developerKey.redirect_uri)
  })

  test('populates the key redirect uris', () => {
    const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'redirect_uris')
    expect(textarea.value).toEqual(developerKey.redirect_uris)
  })

  test('populates the key vendor code', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'vendor_code')
    expect(input.value).toEqual(developerKey.vendor_code)
  })

  test('populates the key icon URL', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'icon_url')
    expect(input.value).toEqual(developerKey.icon_url)
  })

  test('populates the key notes', () => {
    const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'notes')
    expect(textarea.value).toEqual(developerKey.notes)
  })

  test('does not populates the key test_cluster_only without ENV set', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'test_cluster_only')
    expect(input).toEqual(undefined)
  })

  test('populates the key test_cluster_only', () => {
    const env = {
      current_user_id: '1',
      current_user_roles: ['user', 'teacher', 'admin', 'student'],
      current_user_is_admin: true,
      current_user_cache_key: 'users/1-20111116001415',
      context_asset_string: 'user_1',
      domain_root_account_cache_key: 'accounts/1-20111117224337',
      context_cache_key: 'users/1-20111116001415',
      PERMISSIONS: {},
      FEATURES: {},
      enableTestClusterChecks: true,
    }

    const input = formFieldOfTypeAndName(developerKey, 'input', 'test_cluster_only', false, env)
    expect(input.checked).toEqual(developerKey.test_cluster_only)

    window.ENV = {}
  })

  test('does not include legacy redirect uri if lti key', () => {
    expect(formFieldOfTypeAndName(developerKey, 'input', 'redirect_uri', true)).toBeFalsy()
  })

  test('does not include vendor code if lti key', () => {
    expect(formFieldOfTypeAndName(developerKey, 'input', 'vendor_code', true)).toBeFalsy()
  })

  test('does not include icon URL if lti key', () => {
    expect(formFieldOfTypeAndName(developerKey, 'input', 'icon_url', true)).toBeFalsy()
  })

  test('populates the redirect uris if lti key', () => {
    expect(formFieldOfTypeAndName(developerKey, 'textarea', 'redirect_uris')).toBeTruthy()
  })

  test('populates the key name when lti key', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'name')
    expect(input.value).toEqual(developerKey.name)
  })

  test('populates the key owner email when lti key', () => {
    const input = formFieldOfTypeAndName(developerKey, 'input', 'email')
    expect(input.value).toEqual(developerKey.email)
  })

  test('populates the key notes when lti key', () => {
    const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'notes')
    expect(textarea.value).toEqual(developerKey.notes)
  })

  test('renders the tool configuration form if isLtiKey is true', () => {
    window.ENV = {
      validLtiPlacements: [],
      validLtiScopes: {},
    }
    const wrapper = render(
      <DeveloperKeyFormFields
        availableScopes={{}}
        availableScopesPending={false}
        developerKey={developerKey}
        dispatch={() => {}}
        listDeveloperKeyScopesSet={() => {}}
        updateConfigurationMethod={() => {}}
        updateToolConfigurationUrl={() => {}}
        showRequiredMessages={false}
        editing={false}
        tool_configuration={{}}
        configurationMethod="json"
        isLtiKey={true}
      />
    )
    console.log(wrapper.container.innerHTML)
    expect(wrapper.container.querySelector('[name="tool_configuration"]')).toBeTruthy()
  })

  test('renders the developer key scopes form if isLtiKey is false', () => {
    const wrapper = render(
      <DeveloperKeyFormFields
        availableScopes={{}}
        availableScopesPending={false}
        developerKey={developerKey}
        dispatch={() => {}}
        listDeveloperKeyScopesSet={() => {}}
        updateDeveloperKey={() => {}}
        validPlacements={{}}
        isLtiKey={false}
      />
    )

    expect(wrapper.container.querySelector('span[data-automation="enforce_scopes"]')).toBeTruthy()
  })

  test('render a not require `Redirect URIs:` field if isRedirectUriRequired is false', () => {
    const wrapper = render(
      <DeveloperKeyFormFields
        availableScopes={{}}
        availableScopesPending={false}
        developerKey={developerKey}
        dispatch={() => {}}
        listDeveloperKeyScopesSet={() => {}}
        updateDeveloperKey={() => {}}
        validPlacements={{}}
        isLtiKey={false}
        isRedirectUriRequired={false}
      />
    )

    const match = wrapper.container.innerHTML.match(new RegExp(/<span.*>Redirect URIs:<\/span>/))

    expect(match).toBeTruthy()
  })

  test('render a require `* Redirect URIs:` field if isRedirectUriRequired is true', () => {
    const wrapper = render(
      <DeveloperKeyFormFields
        availableScopes={{}}
        availableScopesPending={false}
        developerKey={developerKey}
        dispatch={() => {}}
        listDeveloperKeyScopesSet={() => {}}
        updateDeveloperKey={() => {}}
        validPlacements={{}}
        isLtiKey={false}
        isRedirectUriRequired={true}
      />
    )

    const match1 = wrapper.container.innerHTML.match(
      new RegExp(/<span class=.*>Redirect URIs:<\/span>/)
    )
    expect(match1).toBeFalsy()
    const match2 = wrapper.container.innerHTML.match(
      new RegExp(/<span class=.*>* Redirect URIs:<\/span>/)
    )
    expect(match2).toBeTruthy()
  })
})
