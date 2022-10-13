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
import TestUtils from 'react-dom/test-utils'
import DeveloperKeyFormFields from 'ui/features/developer_keys_v2/react/NewKeyForm'
import fakeENV from 'helpers/fakeENV'
import {mount} from 'enzyme'

QUnit.module('NewKeyForm')

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

function formFieldOfTypeAndName(devKey, fieldType, name, isLtiKey) {
  const component = TestUtils.renderIntoDocument(
    <DeveloperKeyFormFields
      availableScopes={{}}
      availableScopesPending={false}
      developerKey={devKey}
      dispatch={() => {}}
      listDeveloperKeyScopesSet={() => {}}
      isLtiKey={isLtiKey}
    />
  )
  return TestUtils.scryRenderedDOMComponentsWithTag(component, fieldType).find(
    elem => elem.name === `developer_key[${name}]`
  )
}

test('populates the key name', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'name')
  equal(input.value, developerKey.name)
})

test('populates the key owner email', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'email')
  equal(input.value, developerKey.email)
})

test('populates the key legacy redirect uri', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'redirect_uri')
  equal(input.value, developerKey.redirect_uri)
})

test('populates the key redirect uris', () => {
  const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'redirect_uris')
  equal(textarea.value, developerKey.redirect_uris)
})

test('populates the key vendor code', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'vendor_code')
  equal(input.value, developerKey.vendor_code)
})

test('populates the key icon URL', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'icon_url')
  equal(input.value, developerKey.icon_url)
})

test('populates the key notes', () => {
  const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'notes')
  equal(textarea.value, developerKey.notes)
})

test('does not populates the key test_cluster_only without ENV set', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'test_cluster_only')
  equal(input, undefined)
})

test('populates the key test_cluster_only', () => {
  fakeENV.setup({enableTestClusterChecks: true})
  const input = formFieldOfTypeAndName(developerKey, 'input', 'test_cluster_only')
  equal(input.checked, developerKey.test_cluster_only)
  fakeENV.teardown()
})

test('does not include legacy redirect uri if lti key', () => {
  notOk(formFieldOfTypeAndName(developerKey, 'input', 'redirect_uri', true))
})

test('does not include vendor code if lti key', () => {
  notOk(formFieldOfTypeAndName(developerKey, 'input', 'vendor_code', true))
})

test('does not include icon URL if lti key', () => {
  notOk(formFieldOfTypeAndName(developerKey, 'input', 'icon_url', true))
})

test('populates the redirect uris if lti key', () => {
  ok(formFieldOfTypeAndName(developerKey, 'textarea', 'redirect_uris'))
})

test('populates the key name when lti key', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'name')
  equal(input.value, developerKey.name)
})

test('populates the key owner email when lti key', () => {
  const input = formFieldOfTypeAndName(developerKey, 'input', 'email')
  equal(input.value, developerKey.email)
})

test('populates the key notes when lti key', () => {
  const textarea = formFieldOfTypeAndName(developerKey, 'textarea', 'notes')
  equal(textarea.value, developerKey.notes)
})

test('renders the tool configuration form if isLtiKey is true', () => {
  const wrapper = mount(
    <DeveloperKeyFormFields
      availableScopes={{}}
      availableScopesPending={false}
      developerKey={developerKey}
      dispatch={() => {}}
      listDeveloperKeyScopesSet={() => {}}
      isLtiKey
    />
  )
  ok(wrapper.find('ToolConfigurationForm').exists())
})

test('renders the developer key scopes form if isLtiKey is false', () => {
  const wrapper = mount(
    <DeveloperKeyFormFields
      availableScopes={{}}
      availableScopesPending={false}
      developerKey={developerKey}
      dispatch={() => {}}
      listDeveloperKeyScopesSet={() => {}}
      isLtiKey={false}
    />
  )
  ok(wrapper.find('Scopes').exists())
  wrapper.unmount()
})

test('render a not require `Redirect URIs:` field if isRedirectUriRequired is false', () => {
  const wrapper = mount(
    <DeveloperKeyFormFields
      availableScopes={{}}
      availableScopesPending={false}
      developerKey={developerKey}
      dispatch={() => {}}
      listDeveloperKeyScopesSet={() => {}}
      isLtiKey
      isRedirectUriRequired={false}
    />
  )

  const match = wrapper.html().match(new RegExp(/<span.*>Redirect URIs:<\/span>/))

  ok(match)

  wrapper.unmount()
})

test('render a require `* Redirect URIs:` field if isRedirectUriRequired is true', () => {
  const wrapper = mount(
    <DeveloperKeyFormFields
      availableScopes={{}}
      availableScopesPending={false}
      developerKey={developerKey}
      dispatch={() => {}}
      listDeveloperKeyScopesSet={() => {}}
      isLtiKey
      isRedirectUriRequired
    />
  )

  const match1 = wrapper.html().match(new RegExp(/<span class=.*>Redirect URIs:<\/span>/))

  notOk(match1)

  const match2 = wrapper.html().match(new RegExp(/<span class=.*>* Redirect URIs:<\/span>/))

  ok(match2)

  wrapper.unmount()
})
