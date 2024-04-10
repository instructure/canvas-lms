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

import {DeveloperKey} from 'features/developer_keys_v2/model/api/DeveloperKey'
import React, {Component} from 'react'
import TestUtils from 'react-dom/test-utils'
import DeveloperKeyFormFields, {NewKeyFormProps} from '../NewKeyForm'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import ToolConfigurationForm from '../ToolConfigurationForm'
import Scopes from '../Scopes'
import {render} from '@testing-library/react'

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

function defaultProps() {
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
  }
}

function renderWithTestUtils(
  devKey: DeveloperKey,
  isLtiKey: boolean
): Component<DeveloperKeyFormFields> {
  const props = {...defaultProps(), developerKey: devKey, isLtiKey}
  return TestUtils.renderIntoDocument<DeveloperKeyFormFields>(
    <DeveloperKeyFormFields {...props} />
  ) as Component<DeveloperKeyFormFields>
}

function renderWithTestingLibrary(
  devKey: DeveloperKey,
  isLtiKey: boolean,
  extraProps: Partial<NewKeyFormProps> = {}
) {
  const props = {...defaultProps(), developerKey: devKey, isLtiKey, ...extraProps}
  return render(<DeveloperKeyFormFields {...props} />)
}

// Our TS version/settings don't seem to support HTMLElementTagNameMap[T] ...
function inputFieldOfName(devKey: DeveloperKey, name: string, isLtiKey: boolean = false) {
  const component = renderWithTestUtils(devKey, isLtiKey)
  const elem = TestUtils.scryRenderedDOMComponentsWithTag(component, 'input').find(
    e => (e as HTMLInputElement).name === `developer_key[${name}]`
  ) as HTMLInputElement
  return elem
}

function textareaFieldOfName(devKey: DeveloperKey, name: string, isLtiKey: boolean = false) {
  const component = renderWithTestUtils(devKey, isLtiKey)
  const elem = TestUtils.scryRenderedDOMComponentsWithTag(component, 'textarea').find(
    e => (e as HTMLTextAreaElement).name === `developer_key[${name}]`
  ) as HTMLTextAreaElement
  return elem
}

let oldENV: GlobalEnv

beforeAll(() => {
  oldENV = window.ENV
  window.ENV = {
    ...window.ENV,
    validLtiPlacements: ['course_navigation', 'account_navigation'],
    validLtiScopes: {},
  }
})

afterAll(() => {
  window.ENV = oldENV
})

it('populates the key name', () => {
  const input = inputFieldOfName(developerKey, 'name')
  expect(input!.value).toEqual(developerKey.name)
})

it('populates the key owner email', () => {
  const input = inputFieldOfName(developerKey, 'email')
  expect(input!.value).toBe(developerKey.email)
})

it('populates the key legacy redirect uri', () => {
  const input = inputFieldOfName(developerKey, 'redirect_uri')
  expect(input!.value).toEqual(developerKey.redirect_uri)
})

it('populates the key redirect uris', () => {
  const textarea = textareaFieldOfName(developerKey, 'redirect_uris')
  expect(textarea!.value).toEqual(developerKey.redirect_uris)
})

it('populates the key vendor code', () => {
  const input = inputFieldOfName(developerKey, 'vendor_code')
  expect(input!.value).toEqual(developerKey.vendor_code)
})

it('populates the key icon URL', () => {
  const input = inputFieldOfName(developerKey, 'icon_url')
  expect(input!.value).toEqual(developerKey.icon_url)
})

it('populates the key notes', () => {
  const textarea = textareaFieldOfName(developerKey, 'notes')
  expect(textarea!.value).toEqual(developerKey.notes)
})

it('does not populates the key test_cluster_only without ENV set', () => {
  const input = inputFieldOfName(developerKey, 'test_cluster_only')
  expect(input).toEqual(undefined)
})

it('populates the key test_cluster_only', () => {
  window.ENV = {...window.ENV, enableTestClusterChecks: true}
  const input = inputFieldOfName(developerKey, 'test_cluster_only')
  expect(input!.checked).toEqual(developerKey.test_cluster_only)
})

it('does not include legacy redirect uri if lti key', () => {
  const input = inputFieldOfName(developerKey, 'redirect_uri', true)
  expect(input).toBeUndefined()
})

it('does not include vendor code if lti key', () => {
  const input = inputFieldOfName(developerKey, 'vendor_code', true)
  expect(input).toBeUndefined()
})

it('does not include icon URL if lti key', () => {
  const input = inputFieldOfName(developerKey, 'icon_url', true)
  expect(input).toBeUndefined()
})

it('populates the redirect uris if lti key', () => {
  const textarea = textareaFieldOfName(developerKey, 'redirect_uris', true)
  expect(textarea).not.toBeUndefined()
})

it('populates the key name when lti key', () => {
  const input = inputFieldOfName(developerKey, 'name', true)
  expect(input!.value).toBe(developerKey.name)
})

it('populates the key owner email when lti key', () => {
  const input = inputFieldOfName(developerKey, 'email', true)
  expect(input!.value).toBe(developerKey.email)
})

it('populates the key notes when lti key', () => {
  const textarea = textareaFieldOfName(developerKey, 'notes', true)
  expect(textarea!.value).toBe(developerKey.notes)
})

it('renders the tool configuration form if isLtiKey is true', () => {
  const component = renderWithTestUtils(developerKey, true)
  const tcf = TestUtils.scryRenderedComponentsWithType(component, ToolConfigurationForm)
  expect(tcf).toHaveLength(1)
})

it('renders the developer key scopes form if isLtiKey is false', () => {
  const component = renderWithTestUtils(developerKey, false)
  const scopes = TestUtils.scryRenderedComponentsWithType(component, Scopes)
  expect(scopes).toHaveLength(1)
})

it('renders an optional `Redirect URIs:` field if isRedirectUriRequired is false', async () => {
  const rendered = renderWithTestingLibrary(developerKey, true, {isRedirectUriRequired: false})
  expect(await rendered.findByText('Redirect URIs:')).toBeInTheDocument()
  expect(rendered.queryByText('* Redirect URIs:')).not.toBeInTheDocument()
})

it('render a require `* Redirect URIs:` field if isRedirectUriRequired is true', () => {
  const rendered = renderWithTestingLibrary(developerKey, true, {isRedirectUriRequired: true})
  expect(rendered.getByText('* Redirect URIs:')).toBeInTheDocument()
})
